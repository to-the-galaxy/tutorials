# Prometheus deployment with Helm

Update repository and charts:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
```

Install:

```bash
helm install prometheus prometheus-community/kube-prometheus-stack
```

Install with a different release name:

```bash
helm install my-prometheus prometheus-community/kube-prometheus-stack
```

...

...

```bash
kubectl apply --kustomize github.com/kubernetes/ingress-nginx/deploy/grafana/
```

