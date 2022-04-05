# High availability Kubernetes cluster

All components in the cluste will be runing on Ubuntu 20.24 servers. The servers themselves are runing as virtual machines on a Intel NUC running Proxmox 7.

**Summary** of servers, IP addresses, DNS-names, and applications: 

| Type  | Name (server) | Ip  | DNS  | Applications |
|---|---|---|---|---|
| Loadbalancer  | k8sloadbalancer  |  192.168.100.102 | k8sloadbalancer.proxmox.home | Haproxy (and kubectl but it is probably not needed) |
| master node | k8smaster1  |  192.168.100.124 |  k8smaster1.proxmox.home | Kubectl, Kubeadm, Helm and Metal |
| master node | k8smaster2 |  192.168.100.195 |  k8smaster2.proxmox.home | [to be joined as a master] |
|  worker node | k8sworker1 |  192.168.100.118 |  k8sworker1.proxmox.home | [to be joined as a worker] |
| cidr | - | 10.244.0.0/16 | - | [???] |
| DNS | - | 192.168.100.101:8000 | - | PiHole also on in a small cluster |

After creation of the servers, a public ssh-key is copied to each of them, so that it is easy to access them:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub <user-name>@<ip-address>
```
Update all packages on all servers:

```bash
sudo apt update && sudo apt upgrade -y
```

## Brief description of the process of setting up the cluster

The setting up of the cluster involves the following **overall steps and processes**:

1. **Loadbalancer** - which will be the entry point for trafic to services provided by the cluster
   * Install HAproxy
   * Configure `/etc/haproxy/haproxy.cfg` to send traffic to the cluster
   * After configuration, restart `haproxy` with `systemctl`
   * Configure `Sysctl` for Kubernetes networking
2. **Prepare all nodes**, master and worker nodes, which can be done relatively fast using syncronisation in `tmux`
   * Disable firewall (or at least open the right ports)
   * Turn off swap and make it permanent
   * Install with the apt-packet manager: `ca-certificates`, `curl`, `gnupg`, `lsb-release`, and `apt-transport-https`
   * Install (from repository specified below): `docker-ce`, `docker-ce-cli`, and `containerd.io`
   * Configure `containerd.conf` [test if really needed]
   * Configure `/etc/docker/daemon.json`
   * Start and enable`docker` in `systemctl`
   * Configure `modprobe` (overlay and br_netfilter)
   * Setup required `sysctl` params for `/etc/sysctl.d/99-kubernetes-cri.conf`
   * Add Kubernetes repository to the package manager
   * Install `kubeadm`
   * 
3. sss
4. sss
5. ss
6. 

## Setup Loadbalancer

**Install** the `haproxy`:

```bash
sudo apt update && sudo apt install haproxy 
```

Configure by inserting the following the end of `/etc/haproxy/haproxy.cfg`:

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

or

```
############## Configure HAProxy Secure Frontend #############
#frontend k8s-api-https-proxy
#    bind :443
#    mode tcp
#    tcp-request inspect-delay 5s
#    tcp-request content accept if { req.ssl_hello_type 1 }
#    default_backend k8s-api-https

############## Configure HAProxy SecureBackend #############
#backend k8s-api-https
#    balance roundrobin
#    mode tcp
#    option tcplog
#    option tcp-check
#    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
#    server k8s-api-1 192.168.1.101:6443 check
#    server k8s-api-2 192.168.1.102:6443 check
#    server k8s-api-3 192.168.1.103:6443 check

############## Configure HAProxy Unsecure Frontend #############
frontend k8s-api-http-proxy
    bind :80
    mode tcp
    option tcplog
    default_backend k8s-api-http

############## Configure HAProxy Unsecure Backend #############
backend k8s-api-http
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    # server k8s-api-1 192.168.1.101:8080 check
    # server k8s-api-2 192.168.1.102:8080 check
    server k8smaster1 192.168.100.124:80 check fall 3 rise 2
    server k8smaster2 192.168.100.195:80 check fall 3 rise 2
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

## Basic setup of all nodes

...

```bash
sudo su

# General update
apt update
apt upgrade

# Disable firewall    
ufw disable

# Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab
cat /etc/fstab

# Remove old versions
apt remove docker docker-engine docker.io containerd runc

# Install prerequsite packages
apt install ca-certificates curl gnupg lsb-release apt-transport-https -y

# Docker/containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io -y

# Containerd.conf
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Modprobe
modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sysctl --system

# Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
mv ~/kubernetes.list /etc/apt/sources.list.d
apt update
apt install kubeadm -y
```

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
# General update
apt update
apt upgrade

# Disable firewall    
ufw disable

# Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab
cat /etc/fstab

# Remove old versions
apt remove docker docker-engine docker.io containerd runc

# Install prerequsite packages
apt install ca-certificates curl gnupg lsb-release apt-transport-https -y

# Docker/containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io -y

# Containerd.conf
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker




# Modprobe
modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sysctl --system

# Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
mv ~/kubernetes.list /etc/apt/sources.list.d
apt update
apt install kubeadm -y


# Exit sudo su
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

```





```bash
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.0.0.0/16


# new
kubeadm init --control-plane-endpoint="192.168.100.102:6443" --upload-certs --apiserver-advertise-address=192.168.100.124 --pod-network-cidr=10.96.0.0/16

```


# Worker nodes


```bash
sudo su

# General update
apt update
apt upgrade

# Disable firewall    
ufw disable

# Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab
cat /etc/fstab

# Remove old versions
apt remove docker docker-engine docker.io containerd runc

# Install prerequsite packages
apt install ca-certificates curl gnupg lsb-release apt-transport-https -y

# Docker/containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io -y

# Containerd.conf
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker
systemctl daemon-reload
systemctl restart docker




# Modprobe
modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sysctl --system

# Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
mv ~/kubernetes.list /etc/apt/sources.list.d
apt update
apt install kubeadm -y

kubeadm join 192.168.100.102:6443 --token lpksuy.wg7zqvhmm52aokec \
        --discovery-token-ca-cert-hash sha256:09efcaa6d48d385072611bc50ff4300d1402221be0cf82e35502fde6f568c795


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


# Kubeadm reset

```bash
sudo su
kubeadm reset

sudo netstat -tulpn | grep kubelet
```
