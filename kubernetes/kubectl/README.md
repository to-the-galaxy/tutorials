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

# Drain (remove) pods from node
kubectl drain <node-name> --ignore-daemondsets

# Prevent scheduling of pods on node
kubectl cordon <node-name>

# Uncordon node to allow scheduling after a drain
kubectl uncordon <node-name>

# Delete node
kubectl delete node <node-name>

# Find taints of node
kubectl describe node <node-name> | grep taints -i -A 4

# Taint
kubectl taint nodes <node-name> key1=value1:NoSchedule
kubectl taint nodes <node-name> <value>:<taint>

# Remove taint
kubectl taint nodes  <node-name> key1=value1:NoSchedule-
kubectl taint nodes <node-name> <value>:<taint>-

# Remove all evicted pods in default namespace
kubectl get pod | grep Evicted | awk '{print $1}' | xargs kubectl delete pod

# Remove all pods with status of ExitCode, Evicted, ContainerStatusUnknow, Error, Completed
kubectl get pod | grep 'ExitCode\|Evicted\|ContainerStatusUnknown\|Error\|Completed' | awk '{print $1}' | xargs kubectl delete pod

# Remove all pods in specific namespace with status of ExitCode, Evicted, ContainerStatusUnknow, Error, Completed
kubectl get pod -n longhorn-system | grep 'ExitCode\|Evicted\|ContainerStatusUnknown\|Error\|Completed' | awk '{print $1}' | xargs kubectl delete pod -n longhorn-system

```