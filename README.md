# README V1 | SMS Checker – Operation

This repository contains everything needed to **run** the SMS Checker system using Docker Compose.

The system consists of two services:

- **`model-service`** – Python / Flask service that exposes the SMS spam detection model.
- **`app`** – Java / Spring Boot frontend that serves the web UI and calls the backend.

The actual source code lives in separate repositories in the `doda25-team24` GitHub organization and as sibling folders in your local checkout:

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

- Open the frontend in your browser:  
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