# README V1 | SMS Checker – Operation

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

These commands will create and configure the VMs according to the specifications in the Vagrantfile, and apply the Ansible playbooks to set up the Kubernetes cluster.

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

Once the infrastructure is provisioned, deploy the application using Helm. Follow these steps in order:

### 1. Start Minikube

```bash
minikube start --driver=docker --memory=4600MB --cpus=2 --bootstrapper=kubeadm
```

This initializes a local Kubernetes cluster with 4.6GB of memory and 2 CPUs.

### 2. Configure Docker Environment

```bash
eval $(minikube docker-env)
```

This configures the shell to use Minikube's Docker daemon, allowing you to build images directly inside the cluster.

### 3. Build Docker Images

```bash
docker build -t sms-model-service:latest -f ../model-service/Dockerfile ../model-service
docker build -t sms-checker-app:latest -f ../app/Dockerfile ../app
```


### 3. b.(Optional) Load Images into Minikube

If your images aren't appearing in the cluster after building, explicitly load them:

```bash
minikube image load sms-model-service:latest
minikube image load sms-checker-app:latest
```

**Note:** This step may not be necessary on macOS when using `eval $(minikube docker-env)`, but is required on some systems or when using different Minikube profiles.


Builds both the model service and the application images from their respective Dockerfiles.

### 4. Mount Shared Folder

```bash
nohup minikube mount ../model-service/output:/model-service/output > /tmp/minikube-mount.log 2>&1 &
```

This mounts the local `model-service/output` directory into the Minikube VM, allowing persistent data storage between the host and the cluster. The process runs in the background.

### 5. Deploy with Helm

```bash
helm install sms-checker ./sms-checker-chart \
  -f env.yaml \
  --set secret.SMTP_USER=myuser \
  --set secret.SMTP_PASSWORD=mypassword
```

**Replace** `myuser` and `mypassword` with your actual SMTP credentials.

This deploys the application using the Helm chart, applying the environment variables from `env.yaml` and the SMTP credentials you provide.

### 6. Verify Deployment

Check that all resources are created and running:

```bash
# List Helm releases
helm list

# Check pod status
kubectl get pods

# Check services
kubectl get svc

# Check persistent volume claims
kubectl get pvc

# Check persistent volumes
kubectl get pv
```

Wait for all pods to reach the `Running` state before accessing the application. You can watch the pod status in real-time with:

```bash
kubectl get pods -w
```
Check that all resources are created and running:


```bash
# List Helm releases
helm list

# Check pod status
kubectl get pods

# Check services
kubectl get svc

# Check persistent volume claims
kubectl get pvc

# Check persistent volumes
kubectl get pv
```
Wait for all pods to reach the `Running` state before accessing the application. You can watch the pod status in real-time with:

```bash
kubectl get pods -w
```

Pods might take a some time to start. You have to wait until the above command indicates that all pods have reached the `Running` state for the system to be functioning as a whole.



### 7. Monitoring - Gather metrics

Using prometheus are gathering metrics for model-service.
On a separate terminal, enable tunnelling

```bash
sudo minikube tunnel
```

On a separate terminal, enable port forwarding for the new ingress

```bash
 kubectl port-forward svc/ingress-nginx-controller 8000:80 -n ingress-nginx
```

Interact with the app and execute some requests for prometheus to have activity to measure. For that you can port-forward the frontend

```bash
kubectl port-forward svc/sms-checker-app 8080:8080
```
and access the app on 


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

**1. Expose Prometheus:**
```bash
minikube service myprom-kube-prometheus-sta-prometheus
```

**2. Check available targets:**
- Navigate to **Status → Targets**
- Verify both `model-service` and `sms-checker-app` are **UP**

**3. Query metrics:**
- `sms_checks_total`
- `sms_active_requests`
- `sms_prediction_latency_seconds_bucket`

### 📈 Available Metrics

#### Custom Application Metrics (Model Service)

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `sms_checks_total` | Counter | `result` | Total SMS predictions |
| `sms_active_requests` | Gauge | — | Active prediction requests |
| `sms_prediction_latency_seconds` | Histogram | — | Prediction latency |

#### Other system Metrics (Python / Prometheus Client)

- `process_cpu_seconds_total` – Total CPU time consumed
- `process_resident_memory_bytes` – Resident memory size
- `process_virtual_memory_bytes` – Virtual memory size
- `python_gc_objects_collected_total` – Objects collected by garbage collector
- `python_gc_collections_total` – Number of garbage collection runs
- `python_info` – Python runtime information

### ⚙️ Configuration

- Metrics scraping is enabled automatically during Helm installation
- No manual Prometheus configuration is required
- ServiceMonitor resources are created automatically for all services
After running helm install, the metrics endpoints should be available by running the commands:

```bash
curl http://127.0.0.1:8000/metrics/model-service
```
for python backend 

and 

for app frontend-service

