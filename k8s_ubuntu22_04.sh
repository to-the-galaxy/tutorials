#!/bin/bash

echo "Ready to start!!!"
echo "Specify some settings for Kubernetes:"

default_ip=$(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1)

echo "Provide base ip address of server (default is $default_ip)."
read input_base_ip
if [ -z "$input_base_ip" ]
then
    var_base_ip="$default_ip"
else
	var_base_ip=$input_base_ip
fi
echo "Provide value for --control-plane-endpoints (default is $var_base_ip). Don't specify port (script uses default)"
read input_control_plane_endpoint
if [ -z "$input_control_plane_endpoint" ]
then
    var_control_plane_endpoint="$var_base_ip"
else
	var_control_plane_endpoint=$input_control_plane_endpoint
fi
echo "Provide value for --apiserver-advertise-address (default is $var_base_ip)"
read input_api_server_address
if [ -z "$input_api_server_address" ]
then
    var_api_server_address="$var_base_ip"
else
	var_api_server_address=$input_api_server_address
fi
echo "Provide value range for --pod-network (default is 10.244.0.0/16)"
read input_pod_network
if [ -z "$input_pod_network" ]
then
    var_pod_network="10.244.0.0/16"
else
	var_pod_network=$input_pod_network
fi

var_metallb_ip=$(echo $var_base_ip | awk -F . '{printf $1"."$2"."$3}')
var_metallb_ip1="$var_metallb_ip.240"
var_metallb_ip2="$var_metallb_ip.245"

echo "Provide value ip range for Metallb to hand out ip addresses at (default is $var_metallb_ip1-$var_metallb_ip2)"
read input_pod_network
if [ -z "$input_metallb_ip_range" ]
then
    var_metallb_ip_range="$var_metallb_ip1-$var_metallb_ip2"
else
	var_metallb_ip_range=$input_metallb_ip_range
fi
echo "Summary for kubeadm init:"
echo "   --control-plane-endpoint=$var_control_plane_endpoint:6443"
echo "   --apiserver-advertise-address=$var_api_server_address"
echo "   --pod-network-cidr=$var_pod_network"
echo "Summary for metallb"
echo "   spec:"
echo "     addresses:"
echo "     - $var_metallb_ip_range"

read -p "Continue ? " -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
	printf "\nAborting!!!\n "
    exit
fi
echo ""
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
var_containerd_mkdir=$?
var_err=$?
containerd config default > /etc/containerd/config.toml
var_err=$(($var_err+$?))
var_containerd_default_config=$?
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml 
var_containerd_cgroup=$?
var_err=$(($var_err+$?))

cat <<EOF > sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
var_containerd_modules=$?
var_err=$(($var_err+$?))

systemctl restart containerd
systemctl enable containerd
systemctl is-active --quiet containerd > /dev/null 2>&1
var_containerd_service=$?
if [ $var_containerd_service -ne 0 ]
then
	sleep 2
	systemctl is-active --quiet containerd > /dev/null 2>&1
	var_containerd_service=$?
	if [ $? -ne 0]
	then
		sleep 2
		systemctl is-active --quiet containerd > /dev/null 2>&1
		var_containerd_service=$?
	fi
fi
var_err=$(($var_err+$?))

if [ $var_containerd_mkdir -eq 0 ]; then echo "   OK = mkdir /etc/containerd"; else echo "   Error = mkdir"; fi
if [ $var_containerd_cgroup -eq 0 ]; then echo "   OK = SystemdCgroup set to true"; else echo "   Error = setting SystemdCgroupe"; fi
if [ $var_containerd_modules -eq 0 ]; then echo "   OK = kernel modules for containerd"; else echo "   Error = kernel modules"; fi
if [ $var_containerd_service -eq 0 ]; then echo "   OK = containerd restarted, enabled, and active"; else echo "   Error = containerd not active"; fi

if [ $var_err -eq 0 ]
then
	echo "   containerd is configured" 
else
	printf "   Error configuring containerd...\nExiting!!!\n"
	exit
fi

#------------------------------------------------------------------------------
#                                   Swap
#------------------------------------------------------------------------------

echo "** Task == disable swap"
sed -i '/swap/d' /etc/fstab > /dev/null 2>&1
var_swap_fstab=$?
var_err=$?
swapoff -a
var_swap_off=$?
var_err=$(($var_err+$?))

if [ $var_swap_fstab -eq 0 ]; then echo "   OK = swap removed from fstab"; else echo "   Error = editing fstab"; fi
if [ $var_swap_off -eq 0 ]; then echo "   OK = swapoff -a"; else echo "   Error = deactivting swap"; fi

if [ $var_err -eq 0 ]
then
	echo "   swap is configured (turned off)" 
else
	printf "   Error configuring swap...\nExiting!!!\n"
	exit
fi

#------------------------------------------------------------------------------
#                              ufw (firewall)
#------------------------------------------------------------------------------

echo "** Task == disable ufw"
systemctl disable --now ufw > /dev/null 2>&1
var_err=$?
if [ $var_err -eq 0 ]
then
	echo "   ufw is configured (turned off)" 
else
	printf "   Error configuring ufw...\nExiting!!!\n"
	exit
fi

#------------------------------------------------------------------------------
#                              bridge settings
#------------------------------------------------------------------------------

echo "** Task == bridge settings for kubernetes"

cat >>/etc/sysctl.d/kubernetes.conf<<EOF > /dev/null 2>&1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
var_err=$?
var_sysctl_kubernetes=$?
sysctl --system > /dev/null 2>&1
var_err=$(($var_err+$?))
var_sysctl_load_all_sys_conf=$?

if [ $var_sysctl_kubernetes -eq 0 ]; then echo "   OK = kubernetes network bridge added to kernel module"; else echo "   Error = adding to kernel module for kubernetes bridge"; fi
if [ $var_sysctl_load_all_sys_conf -eq 0 ]; then echo "   OK = sysctl --system"; else echo "   Error = running: sysctl --system"; fi

if [ $var_err -eq 0 ]
then
	echo "   kernel modules loaded" 
else
	printf "   Error loading kernel modules...\nExiting!!!\n"
	exit
fi

#------------------------------------------------------------------------------
#                              init kubernetes
#------------------------------------------------------------------------------

echo "** Task == kubeadm init"




#echo "Summary for kubeadm init:"
#echo "   --control-plane-endpoint=$var_control_plane_endpoint:6443"
#echo "   --apiserver-advertise-address=$var_api_server_address"
#echo "   --pod-network-cidr=$var_pod_network"
#echo "Summary for metallb"
#echo "   spec:"
#echo "     addresses:"
#echo "     - $var_metallb_ip_range"



kubeadm init \
  --control-plane-endpoint="$var_control_plane_endpoint:6443" \
  --apiserver-advertise-address="$var_api_server_address" \
  --pod-network-cidr="$var_pod_network"
var_err=$?
if [ $var_err -eq 0 ]; then echo "   OK = kubeadm init succeded"; else echo "   Error = kubeadm init unsuccessful"; fi
read -p "Continue ? " -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    printf "Aborting!!!\n"
    exit
fi


kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-

kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml

kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.4/config/manifests/metallb-native.yaml

cat <<EOF | sudo tee metallb-settings.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - "$var_metallb_ip_range"
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF

sleep 3
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f metallb-settings.yaml

var_metallb_status=$?

if [ $var_metallb_status -ne 0 ]
then
	sleep 5
	kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f metallb-settings.yaml
	var_metallb_status=$?
	if [ $? -ne 0 ]
	then
		sleep 5
		kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f metallb-settings.yaml
		var_metallb_status=$?
	fi
fi

if [ $var_metallb_status -eq 0 ]
then
    echo "Success apply metallb-settings"
else
    echo "Problems applying metallb-settings. Try to run 'kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f metallb-settings.yaml' manually"
fi

echo "Setup kubectl for a specific user"
echo "Enter user name"
read var_user
echo "Var: $var/.kube"

mkdir -p /home/$var_user/.kube
if [ $? -eq 0 ]
   then
       echo "Created folder: /home/$var_user/.kube"
   else
       echo "Could not create /home/$var_user/.kube"
fi

cp -i /etc/kubernetes/admin.conf /home/$var_user/.kube/config
sudo chown $(id -u $var_user):$(id -g $var_user) /home/$var_user/.kube/config