# README | SMS Checker – Operation

This repository contains everything needed to **run** the SMS Checker system using Docker Compose.

The system consists of two services:

- **`model-service`** – Python / Flask service that exposes the SMS spam detection model.
- **`app`** – Java / Spring Boot frontend that serves the web UI and calls the backend.

The actual source code lives in separate repositories in the `doda25-team24` GitHub organization and as sibling folders in the local checkout:

- `../app` – Spring Boot frontend  
- `../model-service` – Python model backend  
- `../lib-version` – Maven library used for versioning

This `operation` repository focuses on **how to start and operate** the system.

---

## Project Layout

Local directory structure:

```
doda25-team24/
├── model-service/     
├── app/               
├── lib-version/       
└── operation/         (current)
```

**Repositories:**
- `model-service`: https://github.com/doda25-team24/model-service
- `app`: https://github.com/doda25-team24/app
- `lib-version`: https://github.com/doda25-team24/lib-version
- `operation`: https://github.com/doda25-team24/operation

---

## Prerequisites

- Docker installed
- Docker Compose available as `docker compose` (or `docker-compose`)
- The `app` and `model-service` repositories present as sibling folders as shown above

No manual build is required: Docker Compose will build both services using the Dockerfiles in `../app` and `../model-service`.

---

## How to Start the Application

From the `operation/` directory:

```bash
# Build images and start both services in the foreground
docker compose up

# Or start them in the background:
docker compose up -d
```

Once both services are up:

- Open the frontend in the browser:  
  **http://localhost:8080/sms**

- The backend (model-service) is reachable inside the Docker network as:  
  **http://model-service:8081**  
  (for example `http://model-service:8081/predict` or `http://model-service:8081/apidocs`)

To stop the application:

```bash
docker compose down
```

If you started the stack with `-d`, you can inspect logs with:

```bash
docker compose logs -f
```

---

## Docker Compose Configuration

The main configuration lives in `docker-compose.yml`.

A typical configuration (matching this project) looks like this:

```yaml
version: '3.8'

services:
  # Backend Service (Python AI Model)
  model-service:
    build:
      context: ../model-service         # Path to the model-service folder
      dockerfile: Dockerfile
      target: production                # Use the production stage of the Dockerfile
    container_name: sms-checker-model-service

    # Port inside the container is controlled by MODEL_PORT (default from code)
    environment:
      - MODEL_PORT=8081

    # Host port 8081 -> container port 8081
    ports:
      - "8081:8081"

    # Persist model output outside the container
    volumes:
      - ../model-service/output:/model-service/output

  # Frontend Service (Spring Boot App)
  app:
    build:
      context: ../app                   # Path to the app folder
      dockerfile: Dockerfile
    container_name: sms-checker-app

    # APP_PORT controls Spring Boot's server.port, MODEL_HOST points to the backend
    environment:
      - APP_PORT=8080
      - MODEL_HOST=http://model-service:8081

    # Host port 8080 -> container port 8080
    ports:
      - "8080:8080"

    # Ensure app container is started after model-service container is created
    depends_on:
      - model-service
```

- **`model-service`** builds and runs the Python backend and exposes the spam detection API.
- **`app`** builds and runs the Spring Boot frontend and sends classification requests to the backend.

---

## Environment Variables (Flexible Containers / F6)

Both containers use environment variables to configure ports and connections, as required by F6: Flexible Containers.

### app service

The `app` service understands the following environment variables:

#### `APP_PORT`
Port on which the Spring Boot application listens inside the container.

In `application.properties` this is configured as:
```properties
server.port=${APP_PORT:8080}
```

If `APP_PORT` is not set, the app defaults to port 8080.

#### `MODEL_HOST`
URL of the model-service as seen from the app container.

By default: `http://model-service:8081`, using the Docker Compose service name (`model-service`) and its internal port.

To run the app on a different port (e.g., 9090) you can change both the environment variable and the port mapping in `docker-compose.yml`.

## Provisioning

To set up the infrastructure for this project, use Vagrant to provision the required virtual machines:

```bash
vagrant up
vagrant provision
```

To execute the finalization.yml file:
```bash
ansible-playbook -u vagrant --private-key=../.vagrant/machines/ctrl/virtualbox/private_key -i 192.168.56.100, finalization.yml
```

These commands will create and configure the VMs according to the specifications in the Vagrantfile, and apply the Ansible playbooks to set up the Kubernetes cluster.

### Accessing the Cluster Dashboard

The provisioning process sets up the Kubernetes Dashboard, which is accessible via a custom local domain.

To access the dashboard, you must update your local hosts file (/etc/hosts on Linux/macOS or C:\Windows\System32\drivers\etc\hosts on Windows) to map the dashboard URL to the Ingress Controller's IP:

```
192.168.56.110 dashboard.local
```

Once configured, you can access the dashboard at: https://dashboard.local


### Project Structure

Here's an overview of the provisioning-related files and directories:

```
├── Vagrantfile              # VM configuration and provisioning settings
├── ansible/                 # Ansible playbooks and configuration
│   ├── ctrl.yaml           # Control plane node configuration
│   ├── files/              # Static files for provisioning
│   ├── finalization.yml    # Final setup tasks
│   ├── hosts               # Ansible inventory file
│   ├── kubeconfig/         # Kubernetes configuration directory
│   │   └── admin.conf      # Cluster admin credentials
│   └── node.yaml           # Worker node configuration
├── docker-compose.yml       # Docker Compose configuration (if needed)
├── env.yaml                 # Environment variables for Helm
├── general.yaml             # General configuration settings
├── kubeconfig/              # Local kubeconfig directory
│   └── admin.conf          # Local copy of admin credentials
└── requirements.txt         # Python dependencies
```

**Key Components:**
- **Vagrantfile**: Defines the VMs (control plane and worker nodes)
- **ansible/**: Contains all Ansible playbooks that configure Kubernetes on the VMs
  - `ctrl.yaml`: Sets up the control plane node
  - `node.yaml`: Configures worker nodes
  - `finalization.yml`: Performs final cluster setup tasks
- **kubeconfig/**: Stores Kubernetes cluster access credentials
- **env.yaml**: Contains environment-specific variables for the Helm deployment

## Running the Helm Chart

Once the infrastructure is provisioned, deploy the application using Helm.

To deploy with helm, simply execute the `setup.sh` file from the operation folder:

```bash
./setup.sh
```

### Monitoring - Gather metrics

Using prometheus to gather metrics for model-service.

On a separate terminal, enable tunnelling

```bash
sudo minikube tunnel
```

Interact with the app and execute some requests for prometheus to have activity to measure. For that you can port-forward the frontend

```bash
kubectl port-forward svc/sms-checker-app 8080:8080
```
and access the app on http://127.0.0.1:8080/sms/

On a separate terminal, enable port forwarding for the new ingress

```bash
 kubectl port-forward svc/ingress-nginx-controller 8000:80 -n ingress-nginx
```


You can also test the python backend directly with:
```bash
curl -X POST http://localhost:8081/predict -H "Content-Type: application/json" -d '{"sms":"Test message"}'
```
expected:
```bash
{
  "classifier": "decision tree",
  "result": "ham",
  "sms": "Test message"
}
```

- Metrics are exposed in Prometheus text format at `/metrics`

- Custom metrics are defined by the application code
- Framework-provided metrics (Spring Boot Actuator) are enabled and exposed explicitly


### Available Metrics

#### On Frontend Service - custom

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `app_sms_spam_predictions_total` | Counter | — | Total SMS spam predictions |
| `app_requests_active` | Gauge | — | Active prediction requests |
| `app_prediction_latency_seconds` | Histogram | — | Prediction request latency |
| `app_prediction_latency_seconds_max` | Gauge | — | Maximum prediction latency |

#### On Model Service - custom

| Metric | Type | Description |
|--------|------|-------------|
| `sms_checks_total` | Counter |  Total SMS predictions |
| `sms_active_requests` | Gauge |  Active prediction requests |
| `sms_prediction_latency_seconds` | Histogram | Prediction latency |

#### some more metrics (python/prometheus client)

- `process_cpu_seconds_total` – Total CPU time consumed
- `process_resident_memory_bytes` – Resident memory size
- `process_virtual_memory_bytes` – Virtual memory size
- `python_gc_objects_collected_total` – Objects collected by garbage collector
- `python_gc_collections_total` – Number of garbage collection runs
- `python_info` – Python runtime information


Metrics scraping is enabled automatically during Helm installation

No manual Prometheus configuration is required

ServiceMonitor resources are created automatically for all services

After running helm install, the metrics endpoints should be available through the ingress, by running the commands:

```bash
curl http://127.0.0.1:8000/metrics/model-service
```
for python backend 

and 
```bash
curl http://127.0.0.1:8000/metrics/sms-checker-app
```
for app frontend-service metrics

You can also expose prometheus and query the metrics abovementioned
**1. Expose Prometheus:**
```bash
minikube service myprom-kube-prometheus-sta-prometheus
```

**2. Check available targets:**
- Navigate to **Status → Targets**
- Verify both `model-service` and `sms-checker-app` are **UP**

#### Visualizing with Grafana

To view the dashboards, port-forward using kubectl:

```bash
kubectl port-forward svc/sms-checker-grafana 3000:80
```
Open Grafana in your browser at `http://localhost:3000/`

Default credentials (from kube-prometheus-stack):
Username: admin
Password: Obtain via
```bash
kubectl get secret --namespace default myprom-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
The grafana dashboard for A3 monitoring is named 'SMS Checker Operations'

#### Continuous experimentation

To run the continous experimentation tests, execute `test_experiments.sh` from the operation folder
```bash
./test_experiments.sh
```

To view the results, follow the same procedure as in the 'Visualizing with Grafana' section. The continuous experimentation dashboard is named 'Experiment Results (Pod View)'





