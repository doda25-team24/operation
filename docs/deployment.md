# SMS Spam Checker: Deployment Architecture

## 1. Overview
This document outlines the deployment structure and data flow for the SMS Spam Checker system on Kubernetes. The system is designed as a microservices architecture leveraging **Istio** for advanced traffic management (canary releases) and the **Kube Prometheus Stack** for comprehensive observability.

The goal of this architecture is to provide a scalable, resilient platform for classifying SMS messages while allowing for safe experimentation with new application versions (v1 vs. v2) using dynamic traffic routing.

## 2. Component Breakdown

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

## 3. Request Data Flow
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

## 4. Access Information

To interact with the deployment, use the following connection details:

| Component | Access Method | Host / Port | Path | Description |
| :--- | :--- | :--- | :--- | :--- |
| **SMS Application** | HTTP (Postman/Curl) | `localhost:8080` (Port-forward) <br> OR `Gateway IP:80` | `/sms` | Main endpoint for classifying messages. |
| **Grafana** | Browser | `localhost:3000` | `/` | Operational Dashboards. |
| **Prometheus** | Browser | `localhost:9090` | `/graph` | Metric queries and target status. |
| **Mailhog** | Browser | `localhost:8025` | `/` | View email alerts triggered by the system. |

## 5. Key Configuration Highlights

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
