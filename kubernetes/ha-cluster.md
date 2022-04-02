# High Availability cluster

## Hardware and server foundation

Create four servers on proxmox, i.e. on the same physical machine. In this case a small Intel NUC.

| Type  | Name | Ip  | DNS  |
|---|---|---|---|
| Loadbalancer  | k8sloadbalancer  |  192.168.100.102 |  k8sloadbalancer.proxmox.home |
| master node | k8smaster1  |  192.168.100.124 |  k8smaster1.proxmox.home |
| master node | k8smaster2 |  192.168.100.195 |  k8smaster2.proxmox.home |
|  worker node | k8sworker1 |  192.168.100.118 |  k8sworker1.proxmox.home |
| cidr | | 10.0.0.0/16 | | 

After creation:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub <user-name>@<ip-address>
```
On all servers:

```bash
sudo apt update && sudo apt upgrade -y
```

## Setup Loadbalancer

```bash
sudo apt update && sudo apt install haproxy 
```

```bash
sudo vim /etc/haproxy/haproxy.cfg
```

```
frontend kubernetes-frontend
    bind 192.168.100.102:6443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    option tcp-check
    balance roundrobin
    server k8smaster1 192.168.100.124:6443 check fall 3 rise 2
    server k8smaster2 192.168.100.195:6443 check fall 3 rise 2
```

Restart and check `haproxy`:

```bash
{
    sudo systemctl restart haproxy
    sudo systemctl status haproxy
}
```

Sysctl for K8s networking

```bash
{
    sudo cat >>/etc/sysctl.d/kubernetes.conf<<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sudo sysctl --system
}
```



## Basic setup of all master and worker nodes

Disable firewall, turn off swap, and remove swap from fstab:

```bash
{
    sudo ufw disable
    sudo swapoff -a;
    sudo sed -i '/swap/d' /etc/fstab
    cat /etc/fstab
}
```

next



Sysctl for K8s networking

```bash
{
    sudo cat >>/etc/sysctl.d/kubernetes.conf<<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sudo sysctl --system
}
```

next

```bash
{
  apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt update && apt install -y docker-ce containerd.io
  apt update && apt install -y kubernetes
```

next





```bash
{
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt update
    sudo apt install -y kubectl
    kubectl version --client --output=yaml
    sudo snap install kubeadm --classic
    sudo snap install kubelet --classic
    sudo apt install socat
    sudo apt install conntrack
}
```


```bash
{
    sudo su
    
}
{
    apt update
    apt install -y apt-transport-https
    apt install -y ca-certificates curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
    sudo mv ~/kubernetes.list /etc/apt/sources.list.d
    apt install kubeadm
}
    
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt update
    sudo apt install -y kubectl
    kubectl version --client --output=yaml
    sudo snap install kubeadm --classic
    sudo snap install kubelet --classic
    sudo apt install socat
    sudo apt install conntrack
}
```


Obs `kubectl cluster-info` will not be working yet, becuase the cluster has not been set up - only its 


# On one a master node (k8smaster1)


```bash
{
    sudo ufw disable
    sudo swapoff -a;
    sudo sed -i '/swap/d' /etc/fstab
    cat /etc/fstab
}

# Remove old versions
apt remove docker docker-engine docker.io containerd runc

apt-get install ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
apt update

apt install install docker-ce docker-ce-cli containerd.io



cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system




{
    sudo cat >>/etc/sysctl.d/kubernetes.conf<<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sudo sysctl --system
}


{
    sudo su
    
}
{
    apt update
    apt install -y apt-transport-https
    apt install -y apt-transport-https
    apt install -y ca-certificates curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
    sudo mv ~/kubernetes.list /etc/apt/sources.list.d
    apt install kubeadm
}

```





```bash
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.0.0.0/16
```



# ...

```
sudo apt install apt-transport-https curl -y
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
sudo mv ~/kubernetes.list /etc/apt/sources.list.d
sudo apt update
sudo apt install -y kubelet kubeadm kubectl kubernetes-cni


kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.244.0.0/16

kubeadm init --upload-certs --pod-network-cidr=10.244.0.0/16



kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```


