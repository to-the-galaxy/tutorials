# Kubernetes install and setup

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
apt install -y apt-transport-https ca-certificates curl
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

## Let normal user access the cluster

```
{
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
}
```
## Intermediary status check

The process above should have initiated or created a small cluster with one node, i.e. a master or control-plane node. To verify this assumtion run `kubectl get nodes` and `kubectl get pods --all-namespaces, which should output something like this:

```
michaell@cassini:~$ kubectl get nodes
NAME      STATUS     ROLES                  AGE   VERSION
cassini   NotReady   control-plane,master   18h   v1.23.5

michael@cassini:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-64897985d-bnsgx           0/1     Pending   0          18h
kube-system   coredns-64897985d-cqpsh           0/1     Pending   0          18h
kube-system   etcd-cassini                      1/1     Running   0          18h
kube-system   kube-apiserver-cassini            1/1     Running   0          18h
kube-system   kube-controller-manager-cassini   1/1     Running   0          18h
kube-system   kube-proxy-nk2hz                  1/1     Running   0          18h
kube-system   kube-scheduler-cassini            1/1     Running   0          18h

```
## Install network layer (flannel)

```
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

## Install MetalLB

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb-frr.yaml
```

Define and deploy a configmap.

```
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
      - 192.168.100.240-192.168.100.250
```

remove tains

kubectl taint nodes cassini node-role.kubernetes.io/master:NoSchedule-
## Some troubleshooting

I had troubles running `kubeadm init ...`, and tried some of these steps:

* Make sure that swap is off (`swapoff -a` and comment it out in the `/etc/fstab`, then reboot).
* `rm -rf /etc/kubernetes/manifests`
* `rm -rf /var/lib/etcd`
* Kill process responsible for open ports that Kubernetes might complain about ` netstat -nlpt|grep :10250` where 10250 is the portnumber (change as needed).







```
michael@cassini:~/temp$ helm install myingress ingress-nginx/ingress-nginx -n ingress-nginx --values ingress-nginx.yaml
NAME: myingress
LAST DEPLOYED: Fri Apr  1 22:13:55 2022
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace ingress-nginx get services -o wide -w myingress-ingress-nginx-controller'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls



michael@cassini:~/temp$ kubectl -n ingress-nginx get all
NAME                                           READY   STATUS    RESTARTS   AGE
pod/myingress-ingress-nginx-controller-6lz48   1/1     Running   0          3m2s

NAME                                                   TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)                      AGE
service/myingress-ingress-nginx-controller             LoadBalancer   10.107.192.253   192.168.100.240   80:32336/TCP,443:30910/TCP   3m2s
service/myingress-ingress-nginx-controller-admission   ClusterIP      10.101.229.100   <none>            443/TCP                      3m2s

NAME                                                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/myingress-ingress-nginx-controller   1         1         1       1            1           kubernetes.io/os=linux   3m2s

```
