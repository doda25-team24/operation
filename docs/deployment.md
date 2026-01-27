# SMS Spam Checker: Deployment Architecture

## 1. Overview
This document outlines the deployment structure and data flow for the SMS Spam Checker system on Kubernetes. The system is designed as a microservices architecture leveraging **Istio** for advanced traffic management (canary releases) and the **Kube Prometheus Stack** for comprehensive observability.

The goal of this architecture is to provide a scalable, resilient platform for classifying SMS messages while allowing for safe experimentation with new application versions (v1 vs. v2) using dynamic traffic routing.

## 2. Architecture Visualization
The following diagram illustrates the high-level components, their relationships, and the flow of traffic through the cluster.

```mermaid
graph TD
    %% External Access
    Client([Client / Curl]) -->|Host: localhost| IG[Istio Ingress Gateway]
    
    %% Traffic Management Layer
    subgraph "Istio Service Mesh"
        IG -->|Gateway Resource| VS[VirtualService]
        VS -.->|Routing Decision| DR[DestinationRule]
    end

    %% Application Layer
    subgraph "Application Workloads"
        direction TB
        
        %% Canary Split Logic
        VS -->|90% Traffic| APP_V1[App v1 Deployment]
        VS -->|10% Traffic| APP_V2[App v2 Deployment]
        
        %% Inter-service Communication
        APP_V1 -->|HTTP POST| MS_SVC[Model Service ClusterIP]
        APP_V2 -->|HTTP POST| MS_SVC
        
        MS_SVC -->|Load Balance| MS_PODS[Model Service Pods v1/v2]
    end

    %% Observability Layer
    subgraph "Observability Stack"
        PROM[Prometheus] -->|Scrapes Metrics /metrics| APP_V1
        PROM -->|Scrapes Metrics /metrics| APP_V2
        PROM -->|Scrapes Metrics| MS_PODS
        
        GRAF[Grafana] -->|Queries| PROM
        PROM -->|Alert Rules| AM[Alertmanager]
        AM -->|SMTP| MH[Mailhog]
    end

    %% Styling
    classDef plain fill:#fff,stroke:#333,stroke-width:2px;
    classDef istio fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;
    classDef obs fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;
    
    class IG,VS,DR istio;
    class PROM,GRAF,AM,MH obs;
    class APP_V1,APP_V2,MS_SVC,MS_PODS plain;

## 3. Component Breakdown

The deployment is divided into three logical layers:

### A. Traffic Management (Istio)
We do not expose our applications directly via standard Kubernetes Ingress. Instead, we use **Istio** to decouple traffic routing from application deployment.
* **Istio Ingress Gateway:** The single entry point into the cluster. It listens for external traffic on standard HTTP ports.
* **VirtualService:** The "Traffic Director." It receives traffic from the gateway and determines where to send it based on paths and weights. This is where the **90/10 canary split** is defined.
* **DestinationRule:** Defines the available "Subsets" (versions) of our application. It tells the mesh that `v1` and `v2` exist and how to identify them (via labels).

### B. Application Workloads
The core logic consists of two decoupled microservices:
1.  **SMS Checker App (Java/Spring Boot):**
    * **Role:** The frontend API that accepts user SMS requests.
    * **Versions:** Two versions (`v1`, `v2`) run simultaneously to test new features.
    * **Communication:** It does not classify messages itself; it acts as a client to the Model Service.
2.  **Model Service (Python/Flask):**
    * **Role:** The "Brain." It hosts the pre-trained Machine Learning model (Pickle format) baked into the Docker image.
    * **Behavior:** Accepts JSON payloads, runs the prediction, and returns `spam` or `ham`.
    * **Scaling:** It is exposed via a standard ClusterIP Service, allowing both App versions to access it seamlessly.

### C. Observability (Monitoring & Alerting)
This layer acts as the "Additional Use Case" for operational reliability.
* **Prometheus:** The central metrics engine. It automatically discovers targets (Pods) via `ServiceMonitors` and scrapes endpoints (`/metrics`) every 15 seconds.
* **Grafana:** Visualization layer connecting to Prometheus to display "Golden Signals" (Latency, Traffic, Errors, Saturation).
* **Alertmanager & Mailhog:** If metrics cross a threshold (e.g., high error rate), Prometheus fires an alert to Alertmanager, which routes an email notification to the local Mailhog SMTP server for testing.

---

## 4. Request Data Flow
A typical request travels through the system as follows:

1.  **Entry:** A client sends a `POST` request to `http://localhost/sms`.
2.  **Gateway Routing:** The **Istio Ingress Gateway** receives the packet and forwards it to the bound **VirtualService**.
3.  **The Decision Point (Dynamic Routing):**
    * The **VirtualService** evaluates the routing rules.
    * It applies the **Weighted Routing** logic configured for the host.
    * **90%** of requests are routed to the `v1` subset (Stable).
    * **10%** of requests are routed to the `v2` subset (Canary).
4.  **Service Processing:**
    * The selected **SMS Checker App** pod receives the request.
    * It parses the text and makes an internal HTTP call to `http://model-service:8081`.
5.  **Prediction:** The **Model Service** processes the input and returns the classification result.
6.  **Response:** The App wraps the result and sends the final HTTP response back to the client.

## 5. Access Information

To interact with the deployment, use the following connection details:

| Component | Access Method | Host / Port | Path | Description |
| :--- | :--- | :--- | :--- | :--- |
| **SMS Application** | HTTP (Postman/Curl) | `localhost:8080` (Port-forward) <br> OR `Gateway IP:80` | `/sms` | Main endpoint for classifying messages. |
| **Grafana** | Browser | `localhost:3000` | `/` | Operational Dashboards. |
| **Prometheus** | Browser | `localhost:9090` | `/graph` | Metric queries and target status. |
| **Mailhog** | Browser | `localhost:8025` | `/` | View email alerts triggered by the system. |

## 6. Key Configuration Highlights

### Where is the Routing Decision Taken?
The dynamic routing decision is **not** taken by the application code or a standard LoadBalancer. It is strictly handled by the **Istio VirtualService** configuration.
* **Location:** The `spec.http.route` section of the VirtualService manifest.
* **Mechanism:** Weighted distribution (`weight: 90`, `weight: 10`) applied to the destination subsets defined in the DestinationRule.

### The "Additional Use Case" Implementation
The monitoring stack implements the additional reliability use case. Unlike the main request flow, this is an asynchronous data flow:
1.  **App & Model** expose metrics at `/metrics`.
2.  **Prometheus** scrapes these endpoints periodically.
3.  **Alert Rules** inside Prometheus evaluate expressions (e.g., `rate(errors) > 0`).
4.  If true, an alert flows from **Prometheus** -> **Alertmanager** -> **Mailhog**, verifying the feedback loop without affecting user traffic.
