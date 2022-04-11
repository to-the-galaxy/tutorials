# Kubectl - Cheat sheet

```bash
# Show all
kubectl get all --all-namespaces

# Apply
kubectl apply -f <yaml-file>

# Show IngressClass
kubectl get ingressclass

# Copy files between host and pods
kubectl cp <source> <destination>

# Edit service, deployment, daemon-set (perhaps others too)
kubectl edit <resource> <name> -n <namespace>

# Scale deployment or replicaset
kubectl scale --replicas=<number> <resource> <name> -n <namespace>

# Describe
kubectl describe <resource> <name>
```