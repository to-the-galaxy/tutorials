#!/bin/bash

echo "** Task == apt update"
 
# apt update and send stdout (1) to /dev/null, and send stderr (2) to the same as stdout
apt update -qq > /dev/null 2>&1

if [ $? -eq 0 ] 
then
	echo "   Updated apt"
else
	echo "   Updating apt failed in full or part"
	exit
fi

echo "** Task == remove old versions of docker, containerd, and runc"
apt remove docker docker.io containerd runc > /dev/null 2>&1

if [ $? -eq 0 ] 
then
	echo "   Cleaning out old versions"
else
	printf "   Removal  failed...\nExiting!!!\n"
	exit
fi

echo "** Task == install apt-transport-https ca-certificates curl"
apt install apt-transport-https ca-certificates curl -y -qq > /dev/null 2>&1

if [ $? -eq 0 ] 
then
	echo "   Installed tools"
else
	printf "   Install failed...\nExiting!!!\n"
	exit
fi

echo "** Task == import docker repo and key" 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
	sudo gpg --dearmor | sudo tee  /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1

if [ $? -eq 0 ] 
then
	echo "   Docker gpg-key downloaded and added to docker-archive-keyring.gpg"
else
	printf "   Import of gpg-key failed...\nExiting!!!\n"
	exit
fi

sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
       	https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >>  /etc/apt/sources.list.d/docker.list

if [ $? -eq 0 ] 
then
	echo "   Docker repo for $(lsb_release -cs) added to /etc/apt/sources.list.d/docker.list"
else
	printf "   Import of gpg-key failed...\nExiting!!!\n"
	exit
fi

echo "** Task == import kubernetes repo and key" 
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

if [ $? -eq 0 ] 
then
	echo "   Kubernetes gpg-key downloaded and added to kubernetes-archive-keyring.gpg"
else
	printf "   Import of gpg-key failed...\nExiting!!!\n"
	exit
fi


echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list

if [ $? -eq 0 ] 
then
	echo "   Kubernetes repo added to /etc/apt/sources.list.d/kubernetes.list"
else
	printf "   Adding repo failed...\nExiting!!!\n"
	exit
fi

echo "** Task == apt update and install kubernetes"

# apt update and send stdout (1) to /dev/null, and send stderr (2) to the same as stdout
apt update -qq > /dev/null 2>&1
var_apt=$?

apt install docker-ce -qq > /dev/null 2>&1
var_apt_docker_ce=$?

apt install docker-ce-cli -qq > /dev/null 2>&1
var_apt_docker_ce_cli=$?

apt install containerd.io -qq > /dev/null 2>&1
var_apt_containerd=$?

apt install kubeadm=1.24.0-00 -qq > /dev/null 2>&1
var_apt_kubeadm=$?

apt install kubelet=1.24.0-00  -qq > /dev/null 2>&1
var_apt_kubelet=$?

apt install kubectl=1.24.0-00 -qq > /dev/null 2>&1
var_apt_kubectl=$?

apt-mark hold kubelet kubeadm kubectl > /dev/null 2>&1
var_apt_mark=$?

if [ $var_apt -eq 0 ]; then echo "   OK = apt update"; else echo "   Error = apt update"; fi
if [ $var_apt_docker_ce -eq 0 ]; then echo "   OK = docker-ce"; else echo "   Error = docker-ce"; fi
if [ $var_apt_docker_ce_cli -eq 0 ]; then echo "   OK = docker-ce-cli"; else echo "   Error = docker-ce-cli"; fi
if [ $var_apt_containerd -eq 0 ]; then echo "   OK = containerd"; else echo "   Error = containerd"; fi
if [ $var_apt_kubeadm -eq 0 ]; then echo "   OK = kubeadm"; else echo "   Error = kubeadm"; fi
if [ $var_apt_kubelet -eq 0 ]; then echo "   OK = kubelet"; else echo "   Error = kubelet"; fi
if [ $var_apt_kubectl -eq 0 ]; then echo "   OK = kubectl"; else echo "   Error = kubectl"; fi
if [ $var_apt_mark -eq 0 ]
then
	echo "   OK = apt-mark hold kubeadm kubelet kubectl"
else
	echo "   Error = apt-mark hold kubeadm kubelet kubectl"
fi

echo "** Task == containerd config"
mkdir -p /etc/containerd > /dev/null 2>&1
var_err=$?
containerd config default > /etc/containerd/config.toml
var_err=$(($var_err+$?))
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml 
var_err=$(($var_err+$?))
if [ $var_err -eq 0 ]
then
	echo "   containerd is configured" 
else
	printf "   Error configuring...\nExiting!!!\n"
	exit
fi



# cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
# overlay
# br_netfilter
# EOF
# # vim /etc/containerd/config.toml # remove cri from disabled plugins, if listed
# systemctl restart containerd
# systemctl enable containerd
# 
# echo "Task ===> disable swap and ufw"
# sed -i '/swap/d' /etc/fstab
# swapoff -a
# systemctl disable --now ufw
# 
# echo "Task ===> bridge settings"
# cat >>/etc/sysctl.d/kubernetes.conf<<EOF
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables  = 1
# net.ipv4.ip_forward                 = 1
# EOF
# 
# sysctl --system
# 
# echo "Task ===> init cluster"
# kubeadm init \
#   --control-plane-endpoint="192.168.56.101:6443" \
#   --apiserver-advertise-address=192.168.56.101 \
#   --pod-network-cidr=10.244.0.0/16
# 
# kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-
# 
# kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml
# 
# kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.4/config/manifests/metallb-native.yaml
# 
# cat <<EOF | sudo tee metallb-settings.yaml
# apiVersion: metallb.io/v1beta1
# kind: IPAddressPool
# metadata:
#   name: first-pool
#   namespace: metallb-system
# spec:
#   addresses:
#   - 192.168.56.200-192.168.56.210
# ---
# apiVersion: metallb.io/v1beta1
# kind: L2Advertisement
# metadata:
#   name: example
#   namespace: metallb-system
# spec:
#   ipAddressPools:
#   - first-pool
# EOF
# 
# kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f metallb-settings.yaml

