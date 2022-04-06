# Initialize and join nodes

**Initialize**

...

...

**Join a worker** 

Generate token and join-command on the master node (the token expires after some time [how much is default???])

```bash
# Generate token
kubeadm token generate

# Create join-command for worker
kubeadm token create <token-from-previous-command> --print-join-command --ttl=0
```

Now, run the join-command on the worker node

```bash
# Example of a join-command
kubeadm join 192.168.100.102:6443 --token hnmudy.qgfufwd78jb9d7sp --discovery-token-ca-cert-hash sha256:544ca839437dd2369cb137fcf982e6f5a1f3e769eef890e9ab9ddf7aff8cf29e
```





```bash
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.0.0.0/16


# new
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.96.0.0/16


kubeadm join 192.168.100.102:6443 --token hnmudy.qgfufwd78jb9d7sp --discovery-token-ca-cert-hash sha256:544ca839437dd2369cb137fcf982e6f5a1f3e769eef890e9ab9ddf7aff8cf29e
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