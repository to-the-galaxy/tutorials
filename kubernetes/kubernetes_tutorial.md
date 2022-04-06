# Kubernetes Tutorial

What is Kubernets?

> Containers let developers focus on their apps while operations focus on the infrastructure—container orchestration is the way you manage these deployments across an enterprise. 
> [Kubernetes](https://www.redhat.com/en/topics/containers/what-is-kubernetes) is an open source container orchestration platform that automates many of the manual processes involved in deploying, managing, and scaling containerized applications.
> 
> *Source*: [Learning Kubernetes basics](https://www.redhat.com/en/topics/containers/learning-kubernetes-tutorial?sc_cid=7013a000002wLwIAAU&gclid=EAIaIQobChMI3b7S56WO9gIVIxkGAB1thgnFEAAYASAAEgJ5_PD_BwE&gclsrc=aw.ds)

# Install Kubernetes on Ubuntu server on Proxmox

**Requirements**

* Proxmox installed on a server
* Ubuntu server installed on Proxmox 
  * Running as a virtual machine (min. 8GB RAM)
  * Applications installed
    - OpenSSH
    - snapd
    - docker
    - w3m (not needed)
    - sipcalc (not needed)
    - minikube (install instruction below)
    - kubectl (install instruction below)

**Names, keys, etc.**

* Proxmox-server
  * IP=192.168.100.10
  * port=8006
* Ubuntu server
  * IP=192.168.100.30
  * name=kubernetes
  * VMID=101

**Installation of Kubernetes**

Access the command-line with:

```shell
ssh michael@192.168.100.30
```

Install Kubernetes with snapd, however, there are alternative ways but using snapd seems to be the easiest; and then test the install by checking the version:

```shell
snap install kubectl --classic
kubectl version --client
```

Now, verify that `kubectl` works. For it to work it must be configured.

> In order for kubectl to find and access a Kubernetes cluster, it needs a [kubeconfig file](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/), which is created automatically when you create a cluster using [kube-up.sh](https://github.com/kubernetes/kubernetes/blob/master/cluster/kube-up.sh) or successfully deploy a Minikube cluster.
> By default, kubectl configuration is located at `~/.kube/config`.
> 
> Check that kubectl is properly configured by getting the cluster state:
> 
> (Source)[[Install and Set Up kubectl on Linux | Kubernetes](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#verify-kubectl-configuration)]

```shell
kubectl cluster-info
```

If this returns a message like:

> The connection to the server localhost:8080 was refused - did you specify the right host or port?

Then `~/.kube/config` is probably missing and a cluster needs to be installed. To do this on a server install `kubeadm` and `kubelet`.

**Install `kubeadm` and `kubelet`**

> You will install these packages on all of your machines:
> 
> - `kubeadm`: the command to bootstrap the cluster.
> 
> - `kubelet`: the component that runs on all of the machines in your cluster
>   and does things like starting pods and containers.
> 
> - `kubectl`: the command line util to talk to your cluster.
> 
> kubeadm **will not** install or manage `kubelet` or `kubectl` for you, so you will
> need to ensure they match the version of the Kubernetes control plane you want kubeadm to install for you. If you do not, there is a risk of a version skew occurring that can lead to unexpected, buggy behaviour. However, *one* minor version skew between the kubelet and the control plane is supported, but the kubelet version may never exceed the API server version. For example, the kubelet running 1.7.0 should be fully compatible with a 1.8.0 API server, but not vice versa.
> 
> Source: [Installing kubeadm | Kubernetes](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)

First install (if not already) `apt-transport-https`, `ca-certificates`, and `curl`:

```shell
sudo apt update && sudo apt-get install -y \
    apt-transport-https ca-certificates curl
```

Download Google Cloud key:

```shell
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```

Add the Kubernetes repository to the `sources.list`:

```shell
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
    https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Now install `kubeadm`, `kubelet`, and `kubectl` (just because the official Kubernetes guide suggests it):

```shell
sudo apt-get update && \
sudo apt-get install -y kubelet kubeadm kubectl && \
sudo apt-mark hold kubelet kubeadm kubectl
```

Note: For some reason it seems to make a difference if one uses `apt-get` instead of `apt`.

**Error continuing**

# Simple Kubernetes cluster with Minikube

`minikube` is a small local Kubernetes cluster.

## Install `minikube`

```shell
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb && sudo dpkg -i minikube_latest_amd64.deb
```

## Create a cluster with Minikube

To create a cluster with `minikube` simply run:

```shell
minikube start
```

The output should be similar to this the first time minicube is started:

```
* minikube v1.25.1 on Ubuntu 20.04 (kvm/amd64)
* Automatically selected the docker driver. Other choices: none, ssh
* Starting control plane node minikube in cluster minikube
* Pulling base image ...
* Downloading Kubernetes v1.23.1 preload ...
    > preloaded-images-k8s-v16-v1...: 504.42 MiB / 504.42 MiB  100.00% 27.53 Mi
    > gcr.io/k8s-minikube/kicbase: 378.98 MiB / 378.98 MiB  100.00% 8.50 MiB p/
* Creating docker container (CPUs=2, Memory=2200MB) ...
* Preparing Kubernetes v1.23.1 on Docker 20.10.12 ...
  - kubelet.housekeeping-interval=5m
  - Generating certificates and keys ...
  - Booting up control plane ...
  - Configuring RBAC rules ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: storage-provisioner, default-storageclass
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

## Interact with the cluster using `kubectl`

`kubectl` is the main program used for interacting with the cluster. Some of the most basice functions of the program are:

```bash
# Get cluster information
kubectl cluster-info

# List all deployments
kubectl get deployments

# List all nodes
kubectl get nodes

# List all pods
kubectl get pods

# List all services
kubectl get services

# List all replicasets
kubectl get replicaset

# Describe a specific deployment, service etc.
kubectl describe deployment <deployment-name>
kubectl describe service <service-name>

# Create a deployment
kubectl create deployment <name> --image=<image-name>

# Apply a deployment
kubectl apply -f <file-name.yaml>

# Edit a deployment
kubectl edit deployment nginx-depl

# Show logs of a pod
kubectl logs <pod-id>

# Enter the pods commandline interface
kubectl exec -it <pssod-id> -- bin/bash

# Delete deployment
kubectl delete <deployment-name>
```

## A small practical example

The objective of this little practical example is to create a cluster on an Ubuntu server running as a virtual machine on Proxmox server. It is assumed that the Ubuntu server (called kubernetes in this example) meets the requirements listed above regarding hardware and software.

Unless otherwise specified, all commands are executed on the Ubuntu server via ssh. Therefore, first ssh into the server:

```bash
ssh michael@192.168.100.30
```

### Start the minikube-cluster

Now, the first order of business is to **start** or **create** the kubernets cluster using `minikube`:

```bash
minikube start
```

Which outputs information about the cluster:

```
michael@kubernetes:~$ minikube start
😄  minikube v1.25.1 on Ubuntu 20.04 (kvm/amd64)
✨  Using the docker driver based on existing profile
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔄  Restarting existing docker container for "minikube" ...
🐳  Preparing Kubernetes v1.23.1 on Docker 20.10.12 ...
    ▪ kubelet.housekeeping-interval=5m
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
    ▪ Using image kubernetesui/dashboard:v2.3.1
    ▪ Using image kubernetesui/metrics-scraper:v1.0.7
🌟  Enabled addons: storage-provisioner, default-storageclass, dashboard
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

### Obtain basic information about the cluster

It is strictly not a necessary step to obtain basic information about the cluster, but it is a good way to learn what exactly is running.

**Cluster information**

```bash
kubectl cluster-info
```

Output

```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

**Nodes**

```bash
kubectl get nodes
```

Output

```
NAME       STATUS   ROLES                  AGE    VERSION
minikube   Ready    control-plane,master   7m2s   v1.23.1
```

**Services**

```bash
kubectl get services
```

Output

```
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   8m20s
```

**Deployments** (none should exist at this point)

```bash
kubectl get deployments
```

Output

```
No resources found in default namespace.
```

### Deploy a little hello-node (echoserver)

Deploy a little hello-node in the form of an echoserver:

```bash
kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4
```

The deployment resultes in the creation a deployment called "hello-node", which is responsible for the creation of a pod. The name of the pod will be: 

```
hello-node-<replicaset-hash>-<pod-hash>
```

For example:

```
hello-node-6b89d599b9-htnq9
```

### Expose hello-node

Expose hello-node on port 8080:

```bash
kubectl expose deployment hello-node --type=NodePort --port=8080
```

When the hello-node was exposed, `kubectl` also created a new service:

```bash
kubectl get service
```

Which outputs

```
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
hello-node   NodePort    10.108.150.79   <none>        8080:31587/TCP   6m10s
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP          6m43s
```

Now the hello-node is exposed to the Ubuntu server on which the node is located, but not the local network. To get the IP-address for the node use:

```bash
kubectl describe node
```

 Output (extract only)

```
Name:               minikube
Roles:              control-plane,master
Labels:             beta.kubernetes.io/arch=amd64

... (text omitted) ...

Addresses:
  InternalIP:  192.168.49.2
  Hostname:    minikube

... (text omitted) ...
```

Use `w3m`or `curl`to access the hello-node over http and view it in the terminal:

```bash
w3m http://192.168.49.2:31587
curl http://192.168.49.2:31587
```

Output

```
CLIENT VALUES:
client_address=172.17.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://192.168.49.2:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=192.168.49.2:31587
user-agent=curl/7.68.0
BODY:
-no body in request-
```

**Warning** it is considered to be bad practise to expose nodes (even locally to the server), because it opens and exposes the node. However, it can be useful for testing.

### Expose hello-node to the LAN

```bash
minikube start --network-plugin=cni --cni=false


curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}


sha256sum --check cilium-linux-amd64.tar.apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      -  192.168.49.240-192.168.49.250gz.sha256sum


sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
cilium install
cilium status
kubectl edit configmap -n kube-system kube-proxy
```

apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true

```
kubectl create deploy nginx --image nginx

kubectl expose deploy nginx --port 80 --type LoadBalancer


kubectl get all
kubectl delete service nginx

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

kubectl get  ns



apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      -  192.168.49.240-192.168.49.250

kubectl create -f metallb.yaml

kubectl expose deploy nginx --port 80 --type LoadBalancer


iptables -t nat -A PREROUTING -p tcp -d 10.0.0.132 --dport 29418 -j DNAT --to-destination 10.0.0.133:29418apt-get install xinetd

apt-get install xinetd
```

### Stop and delete nodes and Minikube

Simply sto the minikube and all deployments and notes will be lost:

```bash
minikube stop
```

Output:

```
✋  Stopping node "minikube"  ...
🛑  Powering off "minikube" via SSH ...
🛑  1 node stopped.
```

# Other stuf

Notice, that the outputlog on th

kubectl` 

Try:

```bash
kubectl get po -A
```

where `get` is a basic command to display one or more resources, and **`po`is ???****

The **output** should be similar to:

```bash
NAMESPACE     NAME                               READY   STATUS    RESTARTS       AGE
kube-system   coredns-64897985d-84fmz            1/1     Running   0              7m36s
kube-system   etcd-minikube                      1/1     Running   0              7m48s
kube-system   kube-apiserver-minikube            1/1     Running   0              7m51s
kube-system   kube-controller-manager-minikube   1/1     Running   0              7m48s
kube-system   kube-proxy-glhgf                   1/1     Running   0              7m37s
kube-system   kube-scheduler-minikube            1/1     Running   0              7m48s
kube-system   storage-provisioner                1/1     Running   1 (7m6s ago)   7m46s
```

Or

```bash
minikube kubectl -- get po -A
```

The **output** should be similar to:

```
    > kubectl.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubectl: 44.43 MiB / 44.43 MiB [-------------] 100.00% 25.88 MiB p/s 1.9s
NAMESPACE     NAME                               READY   STATUS    RESTARTS      AGE
kube-system   coredns-64897985d-84fmz            1/1     Running   0             26m
kube-system   etcd-minikube                      1/1     Running   0             26m
kube-system   kube-apiserver-minikube            1/1     Running   0             26m
kube-system   kube-controller-manager-minikube   1/1     Running   0             26m
kube-system   kube-proxy-glhgf                   1/1     Running   0             26m
kube-system   kube-scheduler-minikube            1/1     Running   0             26m
kube-system   storage-provisioner                1/1     Running   1 (25m ago)   26m
```

> Initially, some services such as the storage-provisioner, may not yet be in a Running state. This is a normal condition during cluster bring-up, and will resolve itself momentarily. For additional insight into your cluster state, minikube bundles the Kubernetes Dashboard, allowing you to get easily acclimated to your new environment:
> 
> *Source:* [minikube start | minikube](https://minikube.sigs.k8s.io/docs/start/)

```shell
minikube dashboard
```

**Minikube runes only locally. Therefore [minikube start | minikube](https://minikube.sigs.k8s.io/docs/start/)** for additional tips and usages.

**Let `minikube dashboard` run in the back ground in its own terminal** 

Output was:

```
* Enabling dashboard ...
  - Using image kubernetesui/dashboard:v2.3.1
  - Using image kubernetesui/metrics-scraper:v1.0.7
* Verifying dashboard health ...
* Launching proxy ...
* Verifying proxy health ...
* Opening http://127.0.0.1:41791/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/ in your default browser...
  http://127.0.0.1:41791/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

To test if the dashboard is being served either - in the case above - run `http://127.0.0.1:41791/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/` in a browser, or if the Minikube is on a server, test if it is up with a `curl` and `grep`command:

```bash
curl http://127.0.0.1:41791/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/ | grep title
```

This should output something like where you see the title:

```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1358    0  1358    0     0   110k      0 --:--:-- --:--:-- --:--:--  221k
  <title>Kubernetes Dashboard</title>
```

## Deploy applications

Create:

```shell
kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
```

The output should be something like:

```
deployment.apps/hello-minikube created
```

Now, expose  the deployment:

```bash
kubectl expose deployment hello-minikube --type=NodePort --port=8080
```

After a few moments the service will show up when you run:

```bash
kubectl get services hello-minikube
```

Output shoud be similar to this:

```
NAME             TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
hello-minikube   NodePort   10.104.203.141   <none>        8080:30517/TCP   116s
```

> The easiest way to access this service is to let minikube launch a web browser for you:
> 
> *Source:* [minikube start | minikube](https://minikube.sigs.k8s.io/docs/start/)

```shell
minikube service hello-minikube
```

> Alternatively, use kubectl to forward the port:
> 
> *Source:* [minikube start | minikube](https://minikube.sigs.k8s.io/docs/start/)

```shell
kubectl port-forward service/hello-minikube 7080:8080
```

Output:

```
Forwarding from 127.0.0.1:7080 -> 8080
Forwarding from [::1]:7080 -> 8080
```

The application is now available at http://localhost:7080/. However, **if minikube is run on a server, and not locally, then it will not show up.** To check if it is working, use `curl`:

```bash
curl http://localhost:7080/
```

Ouput:

```
CLIENT VALUES:
client_address=127.0.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://localhost:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=localhost:7080
user-agent=curl/7.68.0
BODY:
-no body in request-
```

Now it is time to use a `LoadBalancer`:

```bash
kubectl create deployment balanced --image=k8s.gcr.io/echoserver:1.4 
```

Output:

```
deployment.apps/balanced created
```

Now expose it:

```bash
kubectl expose deployment balanced --type=LoadBalancer --port=8080
```

Output:

```
service/balanced exposed
```

> In another window, start the tunnel to create a routable IP for the ‘balanced’ deployment:
> 
> *Source:* [minikube start | minikube](https://minikube.sigs.k8s.io/docs/start/)

```shell
minikube tunnel
```

> To find the routable IP, run this command and examine the `EXTERNAL-IP` column:
> 
> *Source:* [minikube start | minikube](https://minikube.sigs.k8s.io/docs/start/)

```shell
kubectl get services balanced
```

> Your deployment is now available at <EXTERNAL-IP>:8080
> 
> *Source:* [minikube start | minikube](https://minikube.sigs.k8s.io/docs/start/)

Output

```
NAME       TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)          AGE
balanced   LoadBalancer   10.110.184.237   10.110.184.237   8080:31262/TCP   57s
```

## Other commands

```bash
minikube pause
minikube unpause
minikube stop
minikube config set memory 16384
minikube addons list
minikube start -p aged --kubernetes-version=v1.16.1
minikube delete --all
```

```
docker exec -ti 5b5ba29843ab reset-password
New password for default administrator (user-xxxxx):
<new_password>
```

```
docker exec -ti 5b5ba29843ab ensure-default-admin
```

eRROR

```bash
export HTTP_PROXY=http://192.168.100.30:33380
export HTTPS_PROXY=https://192.168.100.30:33443
export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.39.0/24,192.168.49.0/24

minikube start --apiserver-ips=192.168.100.30
```

# Kubernetes cluster from scratch

```bash
#skipping vagrant install

# Ubuntu VM on proxmox

  snap install kube-apiserver

  sudo swapoff -a 

   16  snap install kubectl --classic
   17  sudo snap install kubectl --classic
   18  sudo apt install docker.io -y
mkdir -p /etc/kubernetes/manifests
   11  snap install kubelet --classic
   12  head /etc/kubernetes/kubelet.log
   13  kubelet --pod-manifest-path /etc/kubernetes/manifests &> /etc/kubernetes/kubelet.log &
   14  ps -au | grep kubelet
   15  head /etc/kubernetes/kubelet.log
   16  history  
```

# Common errors

## The connection to the server localhost:8080 was refused - did you specify the right host or port?

> The Kubernetes command-line tool, kubectl, allows you to run commands against Kubernetes clusters. You can use kubectl to deploy applications, inspect and manage cluster resources, and view logs. Kubectl commands are used to interact and manage Kubernetes objects and the cluster. If kubectl does not have the correct credentials to access the cluster this issue may encounter.
> 
> *Source* [The connection to the server localhost:8080 was refused [Solved]](https://k21academy.com/docker-kubernetes/the-connection-to-the-server-localhost8080-was-refused/)

kubeadm config images pull

![](/Users/michael/Library/Application%20Support/marktext/images/2022-02-26-10-48-17-image.png)

![](/Users/michael/Library/Application%20Support/marktext/images/2022-02-26-10-53-29-image.png)

![](/Users/michael/Library/Application%20Support/marktext/images/2022-02-26-12-16-54-image.png)

![](/Users/michael/Library/Application%20Support/marktext/images/2022-02-26-12-17-19-image.png)

    1  sudo apt update
    2  apt search guest-agent
    3  sudo apt install qemu-guest-agent
    4  sudo reboot
    5  uname
    6  uname -a
    7  sudo nano /etc/hostname
    8  sudo nano /etc/hosts
    9  sudo nano /etc/hostname

   10  cat /etc/hostname
   11  cat /etc/hosts
   12  sudo nano /etc/hosts
   13  cat /etc/hosts
   14  snapd --version
   15  snap --version
   16  snap install kubectl --classic
   17  sudo snap install kubectl --classic
   18  sudo apt install docker.io -y
   19  history
   20  sudo -i
   21  minikube tunnel
   22  kubectl
   23  docker --version
   24  kubectl version yaml
   25  ls -a
   26  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   27  curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
   28  echo "$(<kubectl.sha256)  kubectl" | sha256sum --check
   29  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   30  ls
   31  ls -a
   32  kubectl version --client
   33  kubectl version yaml
   34  kubectl get nodes
   35  cd /etc/kubernetes/
   36  ls
   37  ls -a
   38  cd
   39  ls
   40  ls -a
   41  kubeadm init
   42  sudo -i
   43  ls
   44  ls -a
   45  cd /etc/kubernetes/
   46  ls -a
   47  swapoff -a
   48  sudo swapoff -a
   49  kubeadm config images pull
   50  sudo -i
   51  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
   52  cd
   53  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
   54  minikube start
   55  sudo minikube start
   56  sudo minikube start --driver=none
   57  sudo apt install conntrack
   58  sudo minikube start --driver=none
   59  kubectl get nodes
   60  socat
   61  sudo apt install socat
   62  kubectl get nodes
   63  sudo minikube start --driver=none
   64  sudo minikube start --vm-driver=none
   65  sudo rm /tmp/juju*
   66  sudo minikube start --vm-driver=none
   67  systemctl enable kubelet.service
   68  sudo minikube start --vm-driver=none
   69  sudo rm /tmp/juju*
   70  sudo minikube start --vm-driver=none
   71  sudo minikube start --vm-driver=none --ignore-preflight-errors
   72  sudo minikube start --vm-driver=none --ignore-preflight-errors=true
   73  sudo minikube start --vm-driver=none --ignore-preflight-errors
   74  minikube delete
   75  minikube start
   76  sudo usermod -aG docker $USER && newgrp docker
   77  minikube start
   78  kubectl get nodes
   79  git
   80  git clone https://github.com/nigelpoulton/qsk-book.git
   81  ls
   82  cd qsk-book/
   83  ls
   84  cd App/
   85  ls
   86  docker image build -t nigelpoulton/qsk-book:1.0 .
   87  cd
   88  docker images ls
   89  docker image ls
   90  kubectl get nodes
   91  kubectl config get-contex
   92  kubectl config get-context
   93  kubectl config get-contexts
   94  kubectl get nodes
   95  ls
   96  cd qsk-book/
   97  ls
   98  kubectl get pods
   99  kubectl apply -f pod.yml
  100  kubectl get pods
  101  kubectl describe pod first-pod
  102  kubectl apply -f svc-local.yml
  103  kubectl get service
  104  w3m localhost:31111
  105  sudo apt install w3m
  106  w3m localhost:31111
  107  curl localhost:31111
  108  curl -k localhost:31111
  109  curl -k localhost:8080
  110  kubectl apply -f svc-cloud.yml
  111  kubectl get service
  112  w3m localhost:30505
  113  w3m http://localhost:31111
  114  w3m http://localhost:8080
  115  w3m http://localhost
  116  curl localhost
  117  curl localhost:8080
  118  minikube tunneæ
  119  minikube tunnel
  120  kubectl get service
  121  w localhost:80
  122  curl localhost:30505
  123  curl 10.96.104.184
  124  w3m 10.96.104.184
  125  w3m 10.96.104.184
  126  kubectl get pods
  127  kubectl get pods -o wide
  128  kubectl describe first-pod
  129  kubectl describe pod first-pod
  130  kubectl create deployment hello-minikube1 --image=k8s.gcr.io/echoserver:1.4
  131  kubectl get pods -o wide
  132  kubectl expose deployment hello-minikube1 --type=LoadBalancer --port=8080
  133  kubectl expose deployment hello-minikube1 --type=LoadBalancer --port=8888
  134  kubectl get service
  135  w3m 10.111.155.93
  136  kubectl get pods -o wide
  137  w3m 10.111.155.93
  138  w3m 10.96.104.184
  139  w3m 172.17.0.4
  140  w3m 10.96.104.184
  141  w3m 10.111.155.93
  142  history
  143  kubectl get pods -o wide
  144  kubectl get service
  145  curl 10.111.155.93
  146  kubectl get service
  147  w3m 10.96.104.184
  148  ls
  149  cd qsk-book/
  150  ls
  151  cd App
  152  ls
  153  cd ..
  154  ls
  155  vim pod.yml
  156  cp pod.yml pod_2.yaml
  157  vim pod_2.yaml
  158  kubectl apply -f pod_2.yaml
  159  kubectl get pods
  160  vim pod_2.yaml
  161  kubectl apply -f pod_2.yaml
  162  kubectl get pods
  163  kubectl delelte pod second-pod
  164  kubectl delete pod second-pod
  165  kubectl get pods
  166  kubectl apply -f pod_2.yaml
  167  kubectl get pods
  168  kubectl delete pod second-pod
  169  vim pod_2.yaml
  170  mv pod_2.yaml hello_pod.yaml
  171  kubectl apply -f hello_pod.yaml
  172  kubectl get pods
  173  history
  174  kubectl get pods
  175  vim hello_pod.yaml
  176  kubectl get pods
  177  kubectl delete pod second-pod
  178  kubectl apply -f hello_pod.yaml
  179  kubectl get pods
  180  kubectl delete pod second-pod
  181  kubectl delete hellooo
  182  kubectl delete pod hellooo
  183  vim hello_pod.yaml
  184  kubectl create deployment helloworld --image=hello-world
  185  kubectl get pods
  186  minikube stop
  187  minikube start
  188  kubectl create deployment helloworld --image=hello-world
  189  kubectl get deployments
  190  kubectl delete helloworld
  191  kubectl delete deployment helloworld
  192  kubectl create deployment helloworld --image=hello-world
  193  kubectl get deployments
  194  kubectl get pods
  195  kubectl get pods --watch
  196  minikube tunnel
  197  sudo -i
  198  minikube tunnel
  199  kubectl delete pod helloworld
  200  kubectl delete depoloyment
  201  kubectl delete depoloyment helloworld
  202  kubectl delete deployment helloworld
  203  kubectl get pods --watch
  204  kubectl get services
  205  curl 192.168.49.2
  206  kubectl get services
  207  curl 192.168.49.2
  208  ls
  209  cd qsk-book/
  210  ls
  211  cd App/
  212  ls
  213  cd ..
  214  ls
  215  cp App/ myapp/
  216  cp -r App/ myapp/
  217  cd myapp/
  218  ls
  219  vim app.js
  220  cd views/
  221  ls
  222  vim home.pug
  223  cd ..
  224  ls
  225  vim Dockerfile
  226  docker build -t myapp .
  227  cd ..
  228  kubectl get pods
  229  ls
  230  cp pod.yml myapp.yaml
  231  vim myapp
  232  kubectl apply -f myapp.yaml
  233  kubectl get pods --watch
  234  docker images ls
  235  docker ls
  236  docker images
  237  vim myapp
  238  kubectl get pods --watch
  239  kubectl delete deployment myapp
  240  kubectl delete deployment myapp-pod
  241  kubectl delete pod myapp
  242  kubectl get deployment
  243  kubectl get pods
  244  kubectl delete pod myapp-pod
  245  kubectl apply -f myapp.yaml
  246  kubectl get pods --watch
  247  kubectl delete pod myapp-pod
  248  kubectl get pods --watch
  249  vim myapp
  250  vim
  251  ls
  252  vim myapp.yaml
  253  vim pod.yml
  254  kubectl apply -f myapp.yaml
  255  kubectl get pods --watch
  256  docker images ls
  257  cd ..
  258  cd qsk-book/
  259  ls
  260  cd myapp/
  261  ls
  262  vim Dockerfile
  263  docker build -t myapp/myapp .
  264  docker images ls
  265  docker images
  266  cd ..
  267  ls
  268  kubectl create deployment test --image=myapp/myapp:latest
  269  kubectl get pods
  270  kubectl delete pod myapp-po
  271  kubectl delete pod myapp-pod
  272  kubectl delete pod test
  273  kubectl delete pod test-657ddfc5dc-2c6jf
  274  kubectl get pods
  275  kubectl delete deployment test
  276  kubectl get pods
  277  history

# Trying again...

**Install with snap**

```bash
# Required
#sudo snap install kubectl --classic
#sudo snap install kubeadm --classic
#sudo snap install kubelet --classic

sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


sudo apt install docker.io
sudo apt install socat
sudo apt install conntrack

# Useful for troubleshooting
sudo apt install net-tools

# Other requirements
sudo swapoff -a
```

**kubeadm init**

Starting the cluster with `kubeadm init`  required a lot of troubleshooting, and seems to required:

* `docker.service` to be enabled and running (check with `systemctl status docker.service`)

* `kubelet.service` to be enabled and running (check with `systemctl status docker.service`) which seemed to require the install method above for kubelet.

```bash
# Try to initialize the cluster
sudo kubeadm init
```

![](/Users/michael/Library/Application%20Support/marktext/images/2022-02-27-13-16-35-image.png)



```bash
# To run as a regular user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



```bash
# Install Cilium
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}

# Add to active cluster
cilium install
cilium status
```

![](/Users/michael/Library/Application%20Support/marktext/images/2022-02-27-14-45-37-image.png)









**Check**

Check if `~/.kube` exists. If not the cluster is not configured.

**Create or configure cluster**

```bash
# Try
sudo kubeadm init

# Check that docker.service is enabled and running
systemctl status docker.service
# If not
systemctl enable docker.service
systemctl start docker.service
systemctl status docker.service

# Check that kubelet.service is enabled and running
systemctl status kubelet.service
# If not
systemctl start kubelet.service
systemctl enable kubelet.service



# Others
sudo snap remove kubelet




sudo vi /etc/docker/daemon.json
# And insert the following:
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
# then
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl restart kubelet
```
