# Troubleshooting tips

**Kubeadm** fails running`init` or `join`

```bash
# Error: Port 10250 is in use
# Get process keeping the port active and kill it (netstat is in the net-tools package)
sudo netstat -tulpn | grep kubelet
sudo kill <process-id>

# Error: /etc/kubernetes/kubelet.conf already exists or /etc/kubernetes/pki/ca.crt already exists
sudo rm -rf /etc/kubernetes

# Perform a reset
kubeadm reset -f
```

**crisocket**

```bash
# Error execution phase kubelet-start: error uploading crisocket: Unauthorized
# Try
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

# Check that docker and kubelet is both enabled and running (active)
systemctl status docker
systemctl status kubelet

# Systemctl daemond may need a restart
systemctl daemon-restart
systemctl start docker
systemctl start kubelet
```

See this [stackoverflow](https://stackoverflow.com/questions/66816932/worker-node-joining-error-error-execution-phase-kubelet-start-error-uploading).

**Webhook and ingress**: Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io"

```bash
# Get webhooks
kubectl get validatingwebhookconfigurations

# Delete webhooks (one at the time)
kubectl delete validatingwebhookconfigurations <webhook-name>
```

**Ingress problems**

* Always check the `host` value in the ingress yaml-file.
* Check port of the service needed.
* If using a loadbalancer, check how it is configured.

Some troubleshooting that I had to do.

## Kubectl command list

```bash
$ kubectl get namespaces
$ kubectl describe pod <pod-name-checksum> > log.txt
$ kubectl get all --all-namespaces
$ kubectl scale --replicas=3 -f <deployment>.yaml
$ kubectl get pod -o=custom-columns=NODE:.spec.nodeName,NAME:.metadata.name | sort
$ kubectl get pod -o=custom-columns=NODE:.spec.nodeName,NAME:.metadata.name --all-namespaces | sort
$ kubectl get endpoints
$ kubectl kubectl scale --replicas=3 rs/foo
$ kubectl scale --replicas=3 replicaset/xander-nginx-69d64c55db
$ kubectl kubectl get replicasets

[laptop] $ kubectl create deployment nx --image=nginx
[laptop] $ kubectl create service clusterip nx-svc --tcp=80:80
[laptop] $ sudo echo "192.168.56.10 nx.home.test.server.com" | sudo tee -a /etc/hosts
[laptop] $ sudo echo "192.168.56.100 home.lbserver.com" | sudo tee -a /etc/hosts
[laptop] $ sudo cat /etc/hosts
1  curl -sfL https://get.k3s.io | sh -
2  kubectl
3  kubectl get all
4  sudo chmod 644 /etc/rancher/k3s/k3s.yaml
5  kubectl get all
6  kubectl get nodes
7  get pods --all-namespaces
8  kubectl get pods --all-namespaces
9  kubectl run nginx-sample --image=nginx --port=80

# Check status on k3s-agent
$ sudo systemctl status k3s-agent.service
```

## Install VirtualBox kernel to overcome error code -1909

VirtualBox would not start a virtual machine on macOS - not via the VirtualBox UI nor via vagrant. The problem was missing kernel drivers which - perhaps due to security measures in macOS - was not installed.

```bash
[laptop] $ sudo kextload -b org.virtualbox.kext.VBoxDrv
[laptop] $ sudo kextload -b org.virtualbox.kext.VBoxNetFlt
[laptop] $ sudo kextload -b org.virtualbox.kext.VBoxNetAdp
[laptop] $ sudo kextload -b org.virtualbox.kext.VBoxUSB
```

## Install vagrant-scp plugin

Chekc if the plugin is installed, and if not then install it:

```bash
$ vagrant vagrant plugin list
# If not plugins are installed

$ vagrant plugin install vagrant-scp
$ vagrant vagrant plugin list
# Output
vagrant-scp (0.5.9, global)
```

## ErrImagePull and ImagePullBackOff

Try:

* Restart vagrant server
* Update `apk` or `apt`

## Incorrect ip of agent node in K3s

Agent node contacts the master node on ip-address specified here:

```bash
[agent] $ sudo nano /etc/systemd/system/k3s-agent.service.env
```

Sample `k3s-agent.service.env`

```bash
K3S_TOKEN='K1032f3ef13f00b7074fbe9def31a6d9429d84df9e212bd3fd8aa9804a0ff4468f3::server:3c84c8e26487b74a177fe46ee31c0007'
K3S_URL='https://192.168.56.10:6443'
```

And set the agents own ip here:

```bash
[agent] $ sudo nano /etc/systemd/system/k3s-agent.service
```

Sample `k3s-agent.service`

```bash
[Unit]
Description=Lightweight Kubernetes
Documentation=https://k3s.io
Wants=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=exec
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N
EnvironmentFile=-/etc/systemd/system/k3s-agent.service.env
KillMode=process
Delegate=yes
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
ExecStartPre=/bin/sh -xc '! /usr/bin/systemctl is-enabled --quiet nm-cloud-setup.service'
ExecStartPre=-/sbin/modprobe br_netfilter
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/k3s \
    agent \
	'--node-ip=192.168.56.11' \
	'--flannel-iface=eth1' \
```

## Worker nodes not being discovered by the master

Sometimes it helps to ping the worknodes from the master node.



...

..

...

...

make sure correct config maps is available



Good troubleshooting guide: https://jhooq.com/nginx-ingress-controller-crashloopbackoff-error/



