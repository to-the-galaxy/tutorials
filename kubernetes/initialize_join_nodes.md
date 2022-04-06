



```bash
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.0.0.0/16


# new
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.96.0.0/16

```

# 



## Create cluster on a master node

...

```bash
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.244.0.0/16
```

...

## Configure kubectl

...

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

...