# Extension Proposal: Accelerating Change Verification via Continuous Feedback Loops with Skaffold

## 1. Major Shortcoming: The Latency of theDeployment Pipeline

### Description of our Current Workflow
The project currently relies on a "Cold Start" deployment strategy. To complete assignmnets 3 and 4, our project relies on executing a `./setup.sh` script. This makes running the final version easier - but makes it a nightmare during development. To see and verify the correctness of any small change, such as changing a port value in one of the files requires re-running the `./setup.sh` script. This is primary interface for verification - forcing us to wait 5 minutes to see the results of small changes, and this quickly adds up.

This script operates as an imperative automation wrapper that enforces a linear, blocking sequence of operations upon every execution:
1.  **Context Destruction:** The script executes a full teardown of existing releases.
2.  **Artifact Reconstruction:** It triggers a Docker build process which changes build context.
3.  **Registry Synchronization:** Images are pushed to the local container registry, incurring I/O overhead.
4.  **Orchestration Synchronization:** It executes `helm upgrade --install`, forcing the Kubernetes scheduler to terminate old Pods and schedule new ones, regardless of the magnitude of the change.

From a Release Engineering perspective, this workflow represents a misalignment between **Process Weight** and **Change Magnitude**. While a full teardown is appropriate for a clean CI pipeline (to ensure reproducibility), it is catastrophic during development.

#### 1. The "Batching" Risk
The high cost of running `./setup.sh` incentivizes implementing changes to the code in large batches. Throughout development, this led to large pull requests, and changes to the Ingress, the Service definition, and the Prometheus monitors came infrequently in big chunks, violating the CI/CD rule of thumb - "Push early and often". 

#### 2. Higher Rates of Conflicts
This led to multiple synchronization issues due to the irregular pushing and pulling of fresh code. Another major issue, is that it increased the risk of failure due to the updates to multiple subsystems at once.

#### 3. Issues with Reproducibilty
Perhaps the most critical risk is that the high latency encouraged manual 'quick fixes' - which often end up becoming bigger obstacles further during development. For example, this problem directly led to issues with reproducibility among the team, where manual fixes were applied to avoid re-running the `script.sh`. Other team members then had difficulty obtaining the same results at the completion of a stage.

## 2. Proposed Extension: Continuous Configuration Delivery with Skaffold
To resolve these systemic inefficiencies, we propose the integration of **Skaffold**, an open-source project from Google. .

### Conceptual Architecture
Skaffold fundamentally reframes the interaction model with the cluster. It operates as a resident daemon that maintains a file-system watch on specific artifacts (Helm templates, `values.yaml`, Dockerfiles). Upon detecting a `write` event, it computes the minimal delta required to synchronize the cluster state with the local file system.

### Technical Enablers for DevOps
While Skaffold is often marketed for application code, its **value for DevOps Engineering** is profound:

1.  **Smart Helm Upgrades:** Skaffold parses the Helm chart dependency graph. If a developer modifies a specific template (e.g., `templates/virtualservice.yaml`), Skaffold triggers a `helm upgrade`. Crucially, because it maintains the active build context, this operation is often an order of magnitude faster than an external script which typically performs unnecessary pre-checks.
2.  **Drift Correction:** By keeping the tool running, Skaffold acts as a local "GitOps agent." If a developer manually deletes a resource, Skaffold's reconciliation loop (on the next trigger) will detect the absence and restore the resource defined in the local Helm chart.

| Feature | Current State (`./setup.sh`) | Proposed State (`skaffold dev`) |
| :--- | :--- | :--- |
| **Paradigm** | Scripted | Event-Loop |
| **Change Scope** | Global | Atomic |
| **Latency** | 300+ Seconds | < 15 Seconds |
| **Drift Risk** | High | Low  |

## 3. Concrete Implementation Plan
This extension requires a targeted refactoring of the repository's build definitions, estimated at only **2-3 days** of effort.

### Phase 1: The Build/Deploy Definition (Day 1)
Introduce a `skaffold.yaml` manifest.
* **Profile Strategy:** Define a `local` profile specifically for the Minikube environment. This profile will disable image pushing (since we share the Docker daemon with Minikube), saving significant I/O time.
* **Helm Integration:** Map the deploy stanza to use the existing `sms-checker-chart`.

### Phase 2: Configuration Optimization (Day 2&3)
Optimize the pipeline for Infrastructure iteration.
* **Artifact Caching:** We will configure Skaffold to respect Docker layer caching aggressively. If we are only changing `values.yaml`, the build step should be skipped entirely.
* **Tagging Policy:** Implement a tagging policy. Skaffold will tag images with the checksum of the source files. This guarantees that if the source hasn't changed, the Kubernetes scheduler won't needlessly restart the Pods, creating a truly incremental deployment experience.
* **Log Aggregation:** Skaffold streams logs from all containers into a single output, color-coded by pod. This allows a Release Engineer to see the immediate effect of a config change (e.g., "Did the Prometheus sidecar pick up the new scrape config?") without querying `kubectl`.

## 4. Expected Outcomes
The successful implementation of this proposal should yield measurable improvements across three dimensions:

1.  **Velocity (MTTV):** The "Mean Time to Validate" a configuration change will drop from minutes to seconds. This enables "exploratory debugging," where an engineer can rapidly toggle flags (e.g., `istio-injection: enabled/disabled`) to observe behaviors in real-time.
2.  **Stability:** By making the "correct" way to deploy fast, we eliminate the incentive for "manual hacks." The local file system remains the definitive source of truth, reducing the reproducibility errors caused by configuration drift.
3.  **Developer Experience:** Removing the 5-minute wait improves morale and focus. It gets rid of unneccessary wait times.

## 5. Verification Experiment
To objectively validate these claims, we will design a time-taken experiment focusing on Infrastructure tasks.

### Hypothesis
*The introduction of Skaffold will reduce the Verification Latency for configuration changes by >90% compared to the baseline script.*

### Experiment Design
We will define two scenarios typical of a our workflow:

**Scenario A: The "Scaling" Tweak (Helm Values)**
* **Action:** Modify `values.yaml` to increase the Frontend replica count from 1 to 3.
* **Control (Script):** Execute `./setup.sh`. Measure time until `kubectl get pods` reports 3/3 Running. (Baseline: ~240s).
* **Treatment (Skaffold):** Save `values.yaml`. Measure time until `kubectl get pods` reports 3/3 Running. (Target: < 15s).

**Scenario B: The "Routing" Tweak (Istio Manifest)**
* **Action:** Modify `virtualservice.yaml` to inject a 50% fault delay (simulating a chaos test).
* **Control (Script):** Execute `./setup.sh`. Measure time until Kiali shows the delay. (Baseline: ~300s).
* **Treatment (Skaffold):** Save `virtualservice.yaml`. Measure time until Kiali shows the delay. (Target: < 10s).

### Success Criteria
The experiment is successful if the cumulative time for both tasks in the Treatment group is less than **30 seconds**.

## 6. Reflection: Assumptions, Risks, and Downsides

### Theoretical Assumptions
* **Idempotency:** We assume the underlying Helm charts are written idempotently. If the charts contain imperative hooks (e.g., a `pre-install` Job that fails if it already exists), Skaffold's rapid upgrade cycle may expose these fragility bugs.
* **Resource Availability:** The "File Watcher" pattern consumes more RAM than a "One-off Script." We assume the development VM has sufficient overhead to run the daemon alongside the cluster.

### Downsides & Risks
* **The "Clean Slate" Fallacy:** The `./setup.sh` script destroys everything, which guarantees a clean environment. Skaffold applies updates on top of the existing state. There is a risk of old deprecated artefacts conflicting with the development state if not managed properly. This could lead to bugs that only appear in development but not in the clean Production environment.
* **Tooling Fragmentation:** Introducing Skaffold adds another tool to the project stack. It requires maintenance (updates, security patches) and creates a potential divergence between how developers deploy (Skaffold) and how the CI/CD server deploys.


## 7. References
1.  **Google Cloud Architecture Center**, "DevOps tech: Continuous delivery". [Link](https://cloud.google.com/architecture/devops/devops-tech-continuous-delivery). 
2.  **Skaffold Documentation**, "Architecture and Design". [Link](https://skaffold.dev/docs/design/). 
3.  **Google SRE Book**, "Chapter 5: Eliminating Toil". [Link](https://sre.google/sre-book/eliminating-toil/). 
4.  **DORA (DevOps Research and Assessment)**, "Lead Time for Changes". [Link](https://dora.dev/capabilities/lead-time-for-changes/).
