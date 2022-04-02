# High Availability cluster

## Hardware and server foundation

Create four servers on proxmox, i.e. on the same physical machine. In this case a small Intel NUC.

| Type  | Name | Ip  | DNS  |
|---|---|---|---|
| Loadbalancer  | k8sloadbalancer  |  192.168.100.102 |  k8sloadbalancer.proxmox.home |
| master node | k8smaster1  |  192.168.100.124 |  k8smaster1.proxmox.home |
| master node | k8smaster2 |  192.168.100.195 |  k8smaster2.proxmox.home |
|  worker node | k8sworker1 |  192.168.100.118 |  k8sworker1.proxmox.home |

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
}
```

Obs `kubectl cluster-info` will not be working yet, becuase the cluster has not been set up - only its 
