# Full Kubernetes install and setup

Install **dependencies**:

On a server:

```bash
apt-get install -y apt-transport-https ca-certificates curl
```

GPG-key

```bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```

Add repo:

```bash
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Install 

```bash
sudo apt update && sudo apt install kubectl -y
```