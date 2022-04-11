# Initialize and join nodes

**Initialize**

```bash
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.244.0.0/16
```

**Important** the cluster will be initialized with **taints** on master nodes preventing scheduling of nodes. To schedule pods on master nodes these must be removed.

```bash
kubectl describe node <name-of-master-node> | grep taints -i -A 3
kubectl taint nodes <node-name> <key>:<value>-
```

**Install Flannel** to create network overlay (with out Flannel or other service CoreDNS will not work):

```bash
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```

**Join a master**

First, generate token on an existing master node in the cluster 

```bash
# Generate certificate-key
sudo kubeadm init phase upload-certs --upload-certs
# Create join-command for master
kubeadm token create --print-join-command --certificate-key <key-from-previous-step>

# Example of print-join-command
kubeadm token create --print-join-command --certificate-key eec396398abad70161f8ab6106d01e254d4a7e33676aaa1d32be5fd1d2f8a45a

# Example of the output of print-join-command
kubeadm join 192.168.100.102:6443 --token lm11ci.7n641zpcrb5x4tki --discovery-token-ca-cert-hash sha256:533ca989234dd2369cb137aba982e6f5a1f3e769eef890e9ab9ddf7aff8cf29e --control-plane --certificate-key eec396398abad70161f8ab6106d01e254d4a7e33676aaa1d32be5fd1d2f8a45a
```

Now, run the join-command on the master node

```bash
# Example of a join-command
kubeadm join 192.168.100.102:6443 --token hnmudy.qgfufwd78jb9d7sp --discovery-token-ca-cert-hash sha256:544ca839437dd2369cb137fcf982e6f5a1f3e769eef890e9ab9ddf7aff8cf29e
```

**Join a worker** 

Generate token and join-command on the master node (the token expires after some time)

```bash
# Generate token
kubeadm token generate

# Create join-command for worker
kubeadm token create <token-from-previous-command> --print-join-command
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

kubeadm init --control-plane-endpoint="192.168.100.96:6443" --upload-certs --apiserver-advertise-address=192.168.100.96 --pod-network-cidr=10.244.0.0/16