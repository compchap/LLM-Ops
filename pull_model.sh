# Get your pod name
POD_NAME=$(kubectl get pods -n llm-space -l app=ollama -o jsonpath="{.items[0].metadata.name}")

# Execute the pull command inside the container
kubectl exec -it $POD_NAME -n llm-space -- ollama pull llama3.2
