# Longhorn install with Helm in a Kubernetes cluster

```bash
# Required packages (probably already installed) 
sudo apt install open-iscsi bash curl grep
# awk blkid lsblk findmnt

helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install my-longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
kubectl -n longhorn-system get pod
kubectl -n longhorn-system get svc

# Create auth-file (needed for ingress)
htpasswd -c auth <user-name>

# Generate secret
kubectl -n longhorn-system create secret generic basic-auth --from-file=auth

kubectl get secret basic-auth -n longhorn-system -o yaml
```

Troubleshooting:

* If the ingress gives too many troubles, try to delete it/them and apply it agian.

Revision: Originally I had read to create the auth-file with this command, but it then the password is visible in the commandline and its history:

```bash
USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
```