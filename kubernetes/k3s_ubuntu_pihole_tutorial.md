# K3s cluster on Ubuntu server with PiHole

**Highlights**

* Ubuntu server with fixed ip-address of 192.168.100.101 (prerequisite)
* Install K3s on the master node server (just refered to as "server" below)
* Setup a cluster
* Install PiHole on the K3s cluster

## Install K3s

### Master node

Install K3s on the master node.

On **server**, get ip-address and network adapter:

```bash
ip addr
```

Output extract:

```
2: ens18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether ... brd ...
    inet 192.168.100.101/24 brd 192.168.100.255 scope global dynamic ens18
```

On **server**, use the ip-address (192.168.100.101) and network adapter (ens19) in the install script:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.100.101 --flannel-iface=ens18 --write-kubeconfig-mode=644" sh -
```

### Worker nodes

To install K3s worker nodes (refered to just as "worker"), obtain first a node-token on the master node. On **server**:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Now, log on the worker node and obtain its ip-address and network adapter:

```bash
ip addr
```

Now use the node-token from the master, and the ip-address and network adapter from the worker node:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=<ip-addr-of-worker-node> --flannel-iface=eth1" K3S_URL=https://<ip-addr-of-master-node>:6443 K3S_TOKEN=<insert-node-token-from-master-node>  sh -
```

To check the network connection from the master to the work nodes, _which may take time before they are provisioned_, log on the **server** and ping the worker:

```bash
ping <ip-addr-of-worker-node>
```

Check that the worker nodes are in the cluster by running a `kubectl get nodes` from the **server** (master node):

```bash
kubectl get nodes --watch
```

## Configuring `kubectl` 

It is very convenient to configure `kubectl` to work on a client or host machine. In this case the cluster is running on a server (a small desktop pc), and the client is a laptop.

First, on the **server** get the configruation key

```bash
sudo cat /etc/rancher/k3s/k3s.yaml
```

Copy the content of `k3s.yaml` and append it to ~/.kube/config on your client (you may need to create the folder first):

```bash
vim ~/.kube/config
```

Alternatively, after copying (appending) the content of k3s.yaml to ~/.kube/config change - in the just pasted text - the occurances of `default` to a different name, for example `cassiniconfig`. This way you can configure Kubectl to manage multiple different clusters.

Now selete the cassiniconfig context for Kubectl:

```bash
kubectl config use-context cassiniconfig
```

Check that the nodes can be reached:

```bash
kubectl get nodes
```

## Setup persistent storage with Longhorn

The following commands can be executed on the **laptop** or directly on the **server**. I have chosen to use the laptop so that the yaml-files that will be generated are stored on it and can be copied easily to other projects.

Install Longhorn using the official script (here version 1.2.3):

```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.3/deploy/longhorn.yaml
```

Check status of pods being created and run:

```
$ kubectl get pods --namespace longhorn-system --watch
```

Check status of services:

```
$ kubectl -n longhorn-system get svc
```

Create authentication-file called auth (no extension):

```
USER=<user-name>; PASSWORD=<password-of-user>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
```

Create secret from the auth-file:

```
kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
```

Create an ingress for Longhorn:

```
$ cat > longhorn-ingress.yaml <<EOL
@@include[longhorn-ingress.yaml](source/longhorn-ingress.yaml)
EOL
```

Apply the ingress:

```bash
kubectl -n longhorn-system apply -f longhorn-ingress.yaml
```

Test that Longhorn is running

```
curl <ip-of-master-node>:80
```

## Pihole-installation

```bash
# Creat installation yaml-file (reqires Longhorn and K3s and maybe Traefik)
$ cat > pihole-setup.yaml <<EOL
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "1"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
---
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: pihole-custom-dnsmasq
data:
  02-custom.conf: |
    address=/foo.bar/192.168.1.101
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: pihole
  name: pihole
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: pihole
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: pihole
    spec:
      containers:
      # - env:
      #   - name: ServerIP
      #     value: 192.168.56.10
        # - name: WEBPASSWORD
        #   valueFrom:
        #     secretKeyRef:
        #       key: password
        #       name: pihole-webpassword
      - name: pihole
        image: pihole/pihole
        imagePullPolicy: IfNotPresent
        env:
        - name: ServerIP
          value: 192.168.100.101
        ports:
        - containerPort: 80
          name: pihole-http
          protocol: TCP
        - containerPort: 53
          name: dns
          protocol: TCP
        - containerPort: 53
          name: dns-udp
          protocol: UDP
        - containerPort: 443
          name: pihole-ssl
          protocol: TCP
        - containerPort: 67
          name: client-udp
          protocol: UDP
        resources: {}
        # terminationMessagePath: /dev/termination-log
        # terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/pihole
          name: pihole-vol
        # - mountPath: /etc/dnsmasq.d
        #   name: pihole-vol
        - mountPath: /etc/dnsmasq.d/02-custom.conf
          name: custom-dnsmasq
          subPath: 02-custom.conf
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
      - name: pihole-vol
        persistentVolumeClaim:
          claimName: pihole-volume-claim
      - configMap:
          defaultMode: 420
          name: pihole-custom-dnsmasq
        name: custom-dnsmasq
status: {}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pihole-volume-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
# ---
# apiVersion: v1
# kind: PersistentVolumeClaim
# metadata:
#   creationTimestamp: null
#   labels:
#     app: pihole
#   name: pihole-config
# spec:
#   accessModes:
#   - ReadWriteOnce
#   resources:
#     requests:
#       storage: 500Mi
# status: {}
# ---
# apiVersion: v1
# data:
#   password: YWRtaW4K
# kind: Secret
# metadata:
#   name: pihole-webpassword
#   namespace: default
# type: Opaque
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: pihole
  name: pihole-tcp
  namespace: default
spec:
  ports:
  - port: 8000
    targetPort: 80
    name: pihole-admin
  - name: dns
    targetPort: dns
    protocol: TCP
    port: 53
    targetPort: dns
  - name: dns-udp
    targetPort: dns
    protocol: UDP
    port: 53
    targetPort: dns-udp
  selector:
    app: pihole
  sessionAffinity: None
  externalIPs:
  - 192.168.100.101
---
apiVersion: v1
kind: Service
metadata:
  name: pihole-dns-udp
  #namespace: pihole
spec:
  selector:
    app: pihole
  ports:
    - name: 53-udp
      port: 53
      targetPort: 53
      protocol: UDP
  externalTrafficPolicy: Local
  type: LoadBalancer
status:
  loadBalancer:
    ingress:
    - ip: 192.168.100.101
---
apiVersion: v1
kind: Service
metadata:
  name: pihole-dns-tcp
  #namespace: pihole
spec:
  selector:
    app: pihole
  ports:
    - name: 53-tcp
      port: 53
      targetPort: 53
      protocol: TCP
  externalTrafficPolicy: Local
  type: LoadBalancer
status:
  loadBalancer:
    ingress:
    - ip: 192.168.100.101
EOL
# Apply pihole-setup.yaml
$ kubectl apply -f pihole-setup.yaml
# Check that a persistent volumn has been created using the web browser on 192.168.56.100:8000
```

Now reset Pihole password:

```bash
# Get pod id for the PiHole
$ kubectl get pods
# Log on the pod
$ kubectl exec -it pihole-5647ddfb87-l7p9r -- bash
[pod] $ sudo pihole -a -p
# Follow the instructions
# Exit the pod
[pod] $ exit
```
