# Full Kubernetes install and setup

Install **dependencies**:

## On a servers (both master and worker nodes):

```bash
sudo ufw disable
swapoff -a; sed -i '/swap/d' /etc/fstab

cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

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
sudo apt update && sudo apt install kubectl kubeadm -y
```

Install Docker

```bash
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt install docker-ce containerd.io -y
```

## Setup on master node

```bash
sudo kubeadm init --apiserver-advertise-address=192.168.100.120 --pod-network-cidr=10.0.0.0/16

```




