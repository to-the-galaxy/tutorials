# Longhorn install with Helm in a Kubernetes cluster

```bash
# Required packages (probably already installed) 
sudo apt install open-iscsi bash curl findmnt grep
# awk blkid lsblk

helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install my-longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
kubectl -n longhorn-system get pod
kubectl -n longhorn-system get svc

# Authentication and ingress is necessary with a Helm-install
USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth

kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
```

Troubleshooting:

* If the ingress gives too many troubles, try to delete it/them and apply it agian.