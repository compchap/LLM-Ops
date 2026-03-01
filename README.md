# LLM-Ops
Model deployment and Inference

# **Technical Runbook: LLM Deployment on local Kubernetes (k3d)**

## **1\. Overview & Objective**

**Problem:** Deploying and orchestrating Large Language Models (LLMs) on consumer hardware (MacBook) while simulating a production-grade Kubernetes environment. **Solution:** A containerized stack using `k3d` (lightweight K8s), `Ollama` (inference engine), and `Open WebUI` (frontend), configured with persistent storage and ingress routing.

## **2\. Core Architecture & Patterns**

* **Infrastructure-as-Code (IaC):** All resources (Namespaces, PVCs, Deployments, Services, Ingress) are defined in YAML manifests for reproducibility.  
* **Decoupled Inference:** The inference engine (Ollama) and the UI (Open WebUI) are separate deployments communicating over the internal K8s DNS.  
* **Persistence Pattern:** Uses `PersistentVolumeClaims` (PVC) to map host storage to container paths, ensuring model weights ($5GB+$) survive pod restarts.  
* **Traffic Flow:** `User Browser` \-\> `Mac Port 8080` \-\> `k3d LoadBalancer (Port 80)` \-\> `Ingress` \-\> `WebUI Service` \-\> `Ollama Service` \-\> `LLM Inference`.

## **3\. Key Implementation Steps**

1. **Host Prep:** Install Docker Desktop, k3d, and kubectl via Homebrew. Ensure Docker Daemon is initialized (requires system password).

**Cluster Provisioning:**  
k3d cluster create llm-lab \--port "8080:80@loadbalancer" \--agents 2

2.   
3. **Namespace Setup:** Create `llm-space` to isolate resources.  
4. **Engine Deployment:** Apply `ollama-setup.yaml` to provision the 20GB PVC and the Ollama server.  
5. **Model Loading:** Exec into the Ollama pod to pull the desired model (e.g., `llama3.2`).  
6. **UI Deployment:** Apply `webui-setup.yaml` (including Ingress) to expose the frontend.

## **4\. Crucial Files & Logic**

* **`ollama-setup.yaml`:**  
  * `Resources`: Limits set to 4 CPUs / 8GB RAM to protect host stability.  
  * `VolumeMount`: Maps `/root/.ollama` to `ollama-pvc`.  
* **`webui-setup.yaml`:**  
  * `Env`: `OLLAMA_BASE_URL` points to the internal Service DNS `http://ollama-service:11434`.  
  * `Ingress`: Routes traffic from the cluster root `/` to the UI service.  
* **`setup-guide.md`:** Contains the idempotent shell script for environment bootstrapping.

## **5\. "The Why" (Non-obvious Decisions)**

* **Ollama vs. vLLM:** Chose Ollama for Phase 1 due to superior "out-of-the-box" support for Apple Silicon/CPU execution inside Docker. vLLM requires complex CUDA/driver passthrough which is non-trivial in a Mac-K8s VM.  
* **k3d over Minikube:** k3d runs nodes as Docker containers, making it faster to start and lighter on MacBook resources than a full virtual machine.  
* **Ingress over LoadBalancer Service:** Added an explicit Ingress resource because the k3d load balancer (Traefik) requires a routing rule to map host ports to specific internal services correctly, preventing 404 errors.

## **6\. Troubleshooting & Gotchas**

* **Docker Daemon Connection:** `ERROR Cannot connect to Docker`: Occurs if Docker Desktop app isn't open or initialized. Fix: Open Docker.app and wait for the "whale" icon to stabilize.  
* **Port 404 Errors:** If `localhost:8080` returns a 404, verify the Ingress controller has picked up the `webui-ingress`. Use `kubectl describe ingress -n llm-space` to check status.  
* **Docker App Source Missing:** `Error: docker-desktop... is not there`: Homebrew metadata mismatch. Fix: Force uninstall and reinstall the cask.

## **7\. Future Considerations/Scaling**

* **GPU Passthrough:** Explore specialized k3d runtimes or `OrbStack` to expose Metal GPU to the K8s nodes.  
* **HPA (Autoscaling):** Implement `HorizontalPodAutoscaler` based on custom metrics (tokens per second) using a Prometheus exporter.  
* **Model Registry:** Move from local PVCs to a central S3/MinIO bucket for model weight management across multiple nodes.