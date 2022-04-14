# Prometheus and grafana deployment with Helm

Update repository and charts:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo list
helm repo update
```

Install with a any release name (here "my-prometheus":

```bash
helm install my-prometheus prometheus-community/kube-prometheus-stack
```

Output of successful install:

```
LAST DEPLOYED: Sat Apr  9 08:45:41 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace default get pods -l "release=my-prometheus"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

As of writhing this, I have only found one way to connect to Grafana with an ingress-nginx rule, and that require it to be at the root of the domain like this:

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-grafana
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: new.server.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-prometheus-grafana
            port:
              number: 80
  ingressClassName: nginx
```
Therefore, a better approach should be to assign Grafana a better sub-domain, like `grafana.new.server.local`.

Default **credentials**

* Username: `admin`
* Password: `prom-operator`

Get **password**:

```
kubectl get secret my-prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## To-do

* Create and provision persistent storage for prometheus and grafana, for example with Longhorn.'



Create a values-yaml with this content to create a sidecar that looks for configmaps:

```
sidecar:
  dashboards:
    # To enable sidecar
    enabled: true
    # Label key that configMaps should have in order to be mounted 
    label: grafana_dashboard
    # Folder where the configMaps are mounted in Grafana container
    folder: /tmp/dashboards
    # To enable searching configMap accross all namespaces
    searchNamespace: ALL
```

