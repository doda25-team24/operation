# Continuous Experimentation – App Service v2

## Feature Description

A new version of the **app-service (v2)** introduces an optimized request handling path when communicating with the model-service.  
The change reduces synchronous preprocessing logic in the app-service and delegates part of the processing to the model-service, aiming to reduce end-to-end request latency.

The base design (**app-service v1**) performs all preprocessing locally before forwarding the request.

No functional user-facing behavior is changed; the experiment focuses purely on performance and reliability improvements.

## Experiment Hypothesis

**Hypothesis (falsifiable):**  
Compared to **app-service v1**, **app-service v2** reduces request latency without increasing the error rate or reducing request throughput.

If app-service v2 shows higher latency or error rate than v1 under comparable traffic, the hypothesis is rejected.

## Experiment Setup

Two versions of both services are deployed simultaneously.

### Deployed Versions

- **app-service-v1** (baseline)
- **app-service-v2** (candidate)
- **model-service-v1**
- **model-service-v2**

### Consistent Routing

Istio **DestinationRules** and **VirtualServices** are configured to guarantee version-consistent routing:

- app-service-v1 → model-service-v1
- app-service-v2 → model-service-v2
- No cross-version calls (no v1→v2 or v2→v1)

### Traffic Split

Traffic is split at the ingress level:

- **80%** routed to **app-service-v1** (control group)
- **20%** routed to **app-service-v2** (experiment group)

Both versions are exposed under the same hostname to ensure identical user behavior and workload characteristics.

## Metrics Collection

Prometheus scrapes app-specific metrics from both app-service versions.  
Each metric includes a `version` label (`old` or `new`) to enable direct comparison.

### Collected Metrics

- **Request count**
  - `app_requests_total{version}`
- **Request latency histogram**
  - `app_request_duration_seconds_bucket{version}`
- **Error count**
  - `app_request_errors_total{version}`
- **Request rate (derived)**
  - Calculated from `app_requests_total`

## Decision Metrics

### Primary Metric

- **p90 request latency**
  - Derived using  
    `histogram_quantile(0.9, app_request_duration_seconds_bucket)`

### Guardrail Metric

- **Error rate**
  - `app_request_errors_total / app_requests_total`


## Decision Process

1. Observe the dashboard during a stable traffic window (minimum 15 minutes).
2. Compare **p90 latency** between `old` and `new`.
3. Verify that **error rate** for `new` does not exceed `old` by more than 5%.
4. Confirm that both versions receive traffic consistently.

### Acceptance Criteria

Accept **app-service v2** if all of the following are true:

- p90 latency for `new` is **≥15% lower** than `old` for at least 15 minutes
- Error rate for `new` is **not higher than old by more than 5%**
- Request throughput remains stable for both versions

### Rejection Criteria

Reject **app-service v2** if any of the following occur:

- p90 latency for `new` is higher than `old` for more than 10 minutes
- Error rate for `new` exceeds `old` by more than 5% for more than 5 minutes
- Metrics for `new` are missing or incomplete, indicating scraping or labeling issues

## Results
TBC

## Visualization
TBC
