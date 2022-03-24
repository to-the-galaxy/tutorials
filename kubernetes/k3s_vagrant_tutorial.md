# K3s cluster on vagrant virtual machines

Purpose...



## Introductory overview

### System overview

* Host machine: MacBook Pro running macOS Monterey version 12.1
* Applications on host machine:
  
  * VirtualBox
  * Kubectl
  * Vagrant (installed with `brew install vagrant`)
* Vagrant virtual machines
  
  * Kubectl

### Resources and credits

* https://www.youtube.com/watch?v=SLOdZc2uolQ
* 

# Part 1: The most basic setup

## Vagrant virtual machines with K3s

### Install Vagrant and K3s on a local machine







```bash
[macbook] $ brew install kubectl
```





Before setting up vagrant using this tutorial, one should check that the need componets are installed, which is VirtualBox and Vagrant.

```bash
[macbook] $ vagrant --version
Vagrant 2.2.19
[macbook] $ vboxmanage --version
6.1.32r149290
```

Because I had quite some difficulties in getting the virtual machines started with vagrant, I **recommend** that you first launce a virtual machine from the VirtualBox GUI with any linux distribution. This resulted in error code -1909, and it had to do with missing kernels. Below in the **troubleshoot** section I explain the solution to my problem.

With Vagrant it is easy to start a new virtual machine using the command line only, however, to control the settings and easily launch more virtual machines.

### Method 1 - The more manual setup

#### Preparing Vagrant-VMs

This method is based on `Vagrantfile` and `bootstrap.sh` from JustMeAndOpenSource:

```bash
[macbook] $ git clone https://github.com/justmeandopensource/vagrant.git
```

Then `cd` into the ubuntu20-directory:

```bash
[macbook] $ cd vagrant/vagrantfiles/ubuntu20/
```

Then edit the `Vagrant` file where it says `node.vm.network`and add a relevant IP-address. I changed it to `192.168.56.10#{i}`which give nodes starting with `192.168.56.101`. This works for a `NodeCount` not more than 10. I also changed line spacing. 

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :
ENV['VAGRANT_NO_PARALLEL'] = 'yes'
Vagrant.configure(2) do |config|
  config.vm.provision "shell", path: "bootstrap.sh"
  NodeCount = 2 # This determines the number of nodes or virtual machines
  (1..NodeCount).each do |i|
    config.vm.define "ubuntuvm#{i}" do |node|
      node.vm.box               = "generic/ubuntu2004"
      node.vm.box_check_update  = false
      node.vm.box_version       = "3.3.0"
      node.vm.hostname          = "ubuntuvm#{i}.example.com"
      node.vm.network "private_network", ip: "192.168.56.10#{i}" # This determines the ip-range
      node.vm.provider :virtualbox do |v|
        v.name    = "ubuntuvm#{i}" # This determins the name of the machines
        v.memory  = 1024
        v.cpus    = 1
      end
      node.vm.provider :libvirt do |v|
        v.nested  = true
        v.memory  = 1024
        v.cpus    = 1
      end
    end
  end
end
```

Now, run `vagrant` from the directory that contains the `Vagrant`file:

```bash
[macbook] $ vagrant up
```

To check that the virtual machines are running:

```bash
[macbook] $ vagrant global-status

# Output
id       name      provider   state    directory
------------------------------------------------------------------------------------------------------
a15a6aa  ubuntuvm1 virtualbox running  /Users/michael/Documents/Vagrant/vagrant/vagrantfiles/ubuntu20
1f397cb  ubuntuvm2 virtualbox running  /Users/michael/Documents/Vagrant/vagrant/vagrantfiles/ubuntu20
```

To access the virtual machines over ssh:

```bash
[macbook] $ vagrant ssh ubuntuvm1
```

#### Install the `K3s` on the Vagrant-VMs

`K3s` or Kubernetes must be installed on both virtual machines created with vagrant (above), i.e. ubuntuvm1 and ubuntuvm2, but the process is not the same for each machine. The reason for this is that the virtual machines must be connect to form a part of a cluster.

**First** setup `K3s` on ubuntuvm1: To do this, first run `ip add` to get both the ip-address and the third network adapter name (or the second if you don't count the loopback address):

```bash
[ubuntuvm1] $ ip addr

# Output (excerpt)
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
...
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:8c:df:38 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.101/24 brd 192.168.56.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe8c:df38/64 scope link
       valid_lft forever preferred_lft forever
...
```

In my case the information that is important is the the name **eth1** and **192.168.56.101**, and add those to the curl command to install `k3s`:

```bash
[ubuntuvm1] $ curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.101 --flannel-iface=eth1 --write-kubeconfig-mode=644" sh -

# Output
[INFO]  Finding release for channel stable
[INFO]  Using v1.22.7+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.22.7+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.22.7+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s
```

Break-down of the command:

* `curl -sfL https://get.k3s.io`: ... 
* `|` pipes the curl command to the `sh -`
* `INSTALL_K3S_EXEC="--node-ip=192.168.56.101 --flannel-iface=eth1 --write-kubeconfig-mode=644"` is environment variables.
  * `--node-ip` is of course the ip-addresse of the machine on which Kubernetes is being installed
  * `--flannel-iface` 
  * `--write-kubeconfig-mode` defines the permission for the kube configuration. Setting this to `644` means that `kubectl` can run without root permission
* `sh -` takes the environment variables that were pass as it the `sh` were invoked (that is the meaning of `-`)

Now to test the installation, try any of the commands:

```bash
[ubuntuvm1] $ kubectl --version
[ubuntuvm1] $ kubectl get all
```

**Second** step is to setup a node on ubuntuvm2, which is very easy. However, to do that it is essential to obtain the node-token from the first machine, i.e. ubuntuvm1:

```bash
[ubuntuvm1] $ sudo cat /var/lib/rancher/k3s/server/node-token

# Output
K101beea4dd9e371e60ca87cf5331eaa091482774c7b81a555e1d38a2cc1822cebd::server:c65c64382aa0c767b7360a11ec6506eb
```

**Important:** do not share a node-token unless iet is just a temporary test setup as is the case in this tutorial!

Now, on the next machine, start by getting the ip-address and the third network adapter name (or the second if you don't count the loopback address) using `ip addr`:

```bash
[ubuntuvm2] $ ip addr

# Output (excerpt)
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
...
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:ae:8e:b7 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.102/24 brd 192.168.56.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feae:8eb7/64 scope link
       valid_lft forever preferred_lft forever
```

In my case the information that is important is the the name **eth1** and **192.168.56.102**. Now it is time to to install `k3s` and connect it to the cluster using the two parameters as well as the **node-token**:

```bash
[ubuntuvm2] $ curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.102 --flannel-iface=eth1" K3S_URL=https://192.168.56.101:6443 K3S_TOKEN=K101beea4dd9e371e60ca87cf5331eaa091482774c7b81a555e1d38a2cc1822cebd::server:c65c64382aa0c767b7360a11ec6506eb  sh -
```

Test the installation by running `kubectl --version` or `kubectl get all`.

### Method 2 - The more manual setup - New and improved

Create vagrant virtual machines with the following Vagrantfile (adjusted as needed):

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

customParameterName='vagrantVM'
customParameterReplicas = 3
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

# Vagrant.configure(2) means version 2
Vagrant.configure(2) do |config|
  NodeCount = customParameterReplicas
  (1..NodeCount).each do |i|
    config.vm.define "#{customParameterName}#{i}" do |node|
      node.vm.box               = "generic/ubuntu2004"
      node.vm.box_check_update  = false
      node.vm.box_version       = "3.3.0"
      node.vm.hostname          = "#{customParameterName}#{i}.example.com"
      j=9+i
      node.vm.network "private_network", ip: "192.168.56.#{j}"
      node.vm.provider :virtualbox do |v|
        v.name    = "#{customParameterName}#{i}"
        v.memory  = 1024
        v.cpus    = 1
      end
    end
  end
end
```





### Method 3 - The more automated process

I found the following on https://akos.ma/blog/vagrant-k3s-and-virtualbox/ which i adapted the ip-addresses on. Which creates four virtual machines (one server and three agents). This process also installs K3s Create a file with no extensions called `Vagrantfile`  with this content:

Create a `Vagrantfile` as shown below, but 

* adjust, if needed the ip-addresses
* create folders `./shared` in the project home folder 

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

server_ip = "192.168.56.10"

agents = { "agent1" => "192.168.56.11",
           "agent2" => "192.168.56.12",
           "agent3" => "192.168.56.13" 
}

# Extra parameters in INSTALL_K3S_EXEC variable because of
# K3s picking up the wrong interface when starting server and agent
# https://github.com/alexellis/k3sup/issues/306

server_script = <<-SHELL
    sudo -i
    apk add curl
    export INSTALL_K3S_EXEC="--bind-address=#{server_ip} --node-external-ip=#{server_ip} --flannel-iface=eth1"
    curl -sfL https://get.k3s.io | sh -
    echo "Sleeping for 5 seconds to wait for k3s to start"
    sleep 5
    cp /var/lib/rancher/k3s/server/token /vagrant_shared
    cp /etc/rancher/k3s/k3s.yaml /vagrant_shared
    SHELL

agent_script = <<-SHELL
    sudo -i
    apk add curl
    export K3S_TOKEN_FILE=/vagrant_shared/token
    export K3S_URL=https://#{server_ip}:6443
    export INSTALL_K3S_EXEC="--flannel-iface=eth1"
    curl -sfL https://get.k3s.io | sh -
    SHELL

Vagrant.configure("2") do |config|
  config.vm.box = "generic/alpine314"

  config.vm.define "server", primary: true do |server|
    server.vm.network "private_network", ip: server_ip
    server.vm.synced_folder "./shared", "/vagrant_shared"
    server.vm.hostname = "server"
    server.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = "2"
    end
    server.vm.provision "shell", inline: server_script
  end

  agents.each do |agent_name, agent_ip|
    config.vm.define agent_name do |agent|
      agent.vm.network "private_network", ip: agent_ip
      agent.vm.synced_folder "./shared", "/vagrant_shared"
      agent.vm.hostname = agent_name
      agent.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
        vb.cpus = "1"
      end
      agent.vm.provision "shell", inline: agent_script
    end
  end
end
```

Now start the virtual machines from the folder containing `Vagrantfile`.

```bash
[macbook] $ vagrant up
[macbook] $ vagrant global-status

# Output
id       name   provider   state   directory
-----------------------------------------------------------------------
abdda85  server virtualbox running /Users/michael/k3s/voyager
c79ee60  agent1 virtualbox running /Users/michael/k3s/voyager
3aa7d72  agent2 virtualbox running /Users/michael/k3s/voyager
b2028f1  agent3 virtualbox running /Users/michael/k3s/voyager
```

## Configure `kubectl` the host of the virtual machines

This step is strictly speaking not necessary, as all installation activities could be done from the virtual machine, ubuntuvm1, but having `kubectl` on the host machine (or in cases where the cluster is hosted by a different machine or server, the client). To achieve this, install `kubectl` and get a copy of the configuration from ubuntuvm1 and add it to `~/.kube/config` with a slight tweak. When Kubernetes was installed with `K3s` on the ubuntuvm1, the config is located in `/etc/rancher/k3s/k3s.yaml`.

Retrive the configuration from ubuntuvm1 by copying the content from /etc/rancher/k3s/k3s.yaml (on ubuntuvm1) to ~/.kube/config on (macbook).

*Method 1* just copy past the content to ~/.kube/config:

```bash
[server/ubuntuvm1] $ cat /etc/rancher/k3s/k3s.yaml

# Output (excerpt)
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJkekNDQVIyZ0...
    server: https://127.0.0.1:6443
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJrVENDQVRl...
    client-key-data: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSU81cC...
```

Then

```bash
[macbook] $ mkdir ~/.kube
[macbook] $ touch config
[macbook] $ nano config

# Then copy/past the content from your k3s.yaml to config BUT EDIT THE SERVER ADDRESS. This is just an excerpt:
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJkekNDQVIyZ0...
    server: https://192.168.56.101:6443  # <-- EDIT THIS (in my case my server is on 192.168.56.101)
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJrVENDQVRl...
    client-key-data: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSU81cC...
```

*Method 2* is specific for vagrant with and requires a plugin:

```bash
[server/ubuntuvm1] $ cp /etc/rancher/k3s/k3s.yaml /tmp/
```

Then on the receiving machine (here it is macbook):

```bash
[macbook] $ vagrant scp ubuntuvm1:/tmp/k3s.yaml ~/.kube/config
```

Now **test kubectl** is configured correctly:

```bash	
[macbook] $ kubectl cluster-info

# Output
Kubernetes control plane is running at https://192.168.56.101:6443
CoreDNS is running at https://192.168.56.101:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://192.168.56.101:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

## Traefik dashboard

Access the Traefik dashboard:

* Forward port 9000 to 9000 with kubectl
* Open http://localhost:9000/dashboard/ (remeber the "/" in the end of the path)

```bash
[macbook] $ kubectl -n kube-system port-forward <traefik-pod-id> 9000:9000

  kubectl -n kube-system port-forward traefik-56c4b88c4b-dpgh7 9000:9000
```

## Deploy a container to the cluster

To setup the cluster, I have collected all the specifications in one yaml-file, but one could easily have those files separated. To apply the specifications, simply run `kubectl apply -f <filename.yaml>:

```bash
kubectl apply -f minid-deploy-all.yaml
```

The following creates:

* A **service** with type `NodePort`called `minid-app`, with the label pair `app: minid-app`. 
* A **deployment** also called `minid-app`, which creates containers with the name `minid-app`. The containers pull a Docker image called `michaelthumand/minidimg:1.0` (which is in a private repository).
* A **minid-nginx-configmap** (which my not really be used)
* A **service** with type `LoadBalancer`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: minid-app
  labels:
    app: minid-app
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 80
    protocol: TCP
    name: http
  - port: 443
    protocol: TCP
    name: https
  selector:
    app: minid-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minid-app
spec:
  selector:
    matchLabels:
      app: minid-app
  replicas: 2
  template:
    metadata:
      labels:
        app: minid-app
    spec:
      containers:
      - name: minid-app
        image: michaelthumand/minidimg:1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        - containerPort: 443
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: minid-nginx-configmap
  namespace: default
---
apiVersion: v1
kind: Service
metadata:
  name: example-service
spec:
  selector:
    app: minid-app
  ports:
    - port: 81
      targetPort: 80
  type: LoadBalancer
```

To **test** that everything is working open a browser on the host machine (i.e. the MacBook in my case) and go to these addresses:

* http://192.168.56.101:81 -> which should display a little webpage that is baked into the image
* http://192.168.56.101 -> which should show, a `page not found message`, which as the above show that the webserver is up and running (though no site is mapped for the default port).

## Delete and clean up the virtual machines

Stop and destroy the containers:

```bash
[macbook] $ vagrant halt
[macbook] $ vagrant global-status
[macbook] $ vagrant destroy <id-of-vm1> <id-of-vm2> 
```

# Part 2: The Voyager-project with three web servers

This tutorial assumes the following configruations are in places

* Host machines: *macbook*
* Vagrant VMs:
  * *server*, ip-address 192.168.56.10
  * *agent1*, ip-address 192.168.56.11
  * *agent2*, ip-address 192.168.56.12
  * *agent3*, ip-address 192.168.56.13

* Shared folder: ./shared
* `kubectl` configured on *macbook*
* Traefik dashboard is configured to run on the macbook on localhost and port 9000 (http://localhost:9000/dashboard/ (remeber the "/" in the end of the path))

Test running pods

```bash
[macbook] $ kubectl get all --all-namespaces

# Output (extract)
NAMESPACE     NAME                                          READY   STATUS      RESTARTS   AGE
kube-system   pod/coredns-96cc4f57d-kdjcf                   1/1     Running     0          21h
kube-system   pod/local-path-provisioner-84bb864455-c5jns   1/1     Running     0          21h
kube-system   pod/helm-install-traefik-crd--1-nmtv4         0/1     Completed   0          21h
kube-system   pod/helm-install-traefik--1-rwdpg             0/1     Completed   1          21h
kube-system   pod/metrics-server-ff9dbcb6c-9qrh4            1/1     Running     0          21h
kube-system   pod/svclb-traefik-gzf6z                       2/2     Running     0          21h
kube-system   pod/svclb-traefik-4zvc4                       2/2     Running     0          21h
kube-system   pod/traefik-56c4b88c4b-j2x26                  1/1     Running     0          21h
kube-system   pod/svclb-traefik-47j2p                       2/2     Running     0          21h
kube-system   pod/svclb-traefik-zxxr4                       2/2     Running     0          21h

NAMESPACE     NAME                     TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
default       service/kubernetes       ClusterIP      10.43.0.1       <none>          443/TCP                      21h
kube-system   service/kube-dns         ClusterIP      10.43.0.10      <none>          53/UDP,53/TCP,9153/TCP       21h
kube-system   service/metrics-server   ClusterIP      10.43.189.132   <none>          443/TCP                      21h
kube-system   service/traefik          LoadBalancer   10.43.125.19    192.168.56.10   80:30505/TCP,443:31506/TCP   21h
...
```

## Deploy a whoami-webserver

Create a `whomi.yaml` file with the following content and deploy it and to access it added it to the /etc/hosts.

```yaml
# Who-am-i project
# * deployment
# * service
# * ingress (simple)
# based on:
# * https://github.com/traefik-workshops/traefik-workshop/tree/master/exercise-3
# * https://github.com/traefik-workshops/traefik-workshop/tree/master/exercise-4
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: whoami
  name: whoami
spec:
  replicas: 1
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - image: traefik/whoami:latest
          imagePullPolicy: IfNotPresent
          name: whoami
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami-svc
spec:
  type: ClusterIP
  selector:
    app: whoami
  ports:
    - port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami-http
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
    - host: home.test.server.com
      http:
        paths:
          - path: /
            pathType: Exact
            backend:
              service:
                name: whoami-svc
                port:
                  number: 80
```

Deploy the configuration:

```bash
[macbook] $ kubectl apply -f whoami.yaml
```

This cluster running on vagrant virtual machines have a load-balancer service on 192.168.56.10, and to access it from a domain name, it has been added to the local hosts file:

```bash
[macbook] $ sudo nano /etc/hosts

# Then add the following entry:
192.168.56.10 home.test.server.com
```

or by

```bash
[macbook] $ sudo echo "192.168.56.10 home.test.server.com" | sudo tee -a /etc/hosts
```

**Now test the response** from http://whoami.home.test.server.com in a web browser, or by

```bash
[macbook] $ curl http://home.test.server.com -v

# Output
*   Trying 192.168.56.101:80...
* connect to 192.168.56.101 port 80 failed: Operation timed out
*   Trying 192.168.56.10:80...
* Connected to home.test.server.com (192.168.56.10) port 80 (#0)
> GET / HTTP/1.1
> Host: home.test.server.com
> User-Agent: curl/7.77.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Length: 419
< Content-Type: text/plain; charset=utf-8
< Date: Sat, 12 Mar 2022 19:00:21 GMT
<
Hostname: whoami-664987c5d4-hws5d
IP: 127.0.0.1
IP: ::1
IP: 10.42.1.11
IP: fe80::c4c5:d3ff:fe84:9f98
RemoteAddr: 10.42.1.8:57438
GET / HTTP/1.1
Host: home.test.server.com
User-Agent: curl/7.77.0
Accept: */*
Accept-Encoding: gzip
X-Forwarded-For: 10.42.0.0
X-Forwarded-Host: home.test.server.com
X-Forwarded-Port: 80
X-Forwarded-Proto: http
X-Forwarded-Server: traefik-56c4b88c4b-j2x26
X-Real-Ip: 10.42.0.0

* Connection #0 to host home.test.server.com left intact
```

## Deploy two simple web servers

### Create configuration for server 1 - nginx-xander

Add the following content to nginx-xander.yaml:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xander-nginx
  labels:
    app: xander-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xander-nginx
  template:
    metadata:
      labels:
        app: xander-nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html-volume
        configMap:
          name: xander-html
---
apiVersion: v1
kind: Service
metadata:
  name: xander-nginx-service
spec:
  selector:
    app: xander-nginx
  ports:
    - protocol: TCP
      port: 80
---
apiVersion: v1
data:
  index.html: |-
    <html>
    <head><title>K3S!</title>
      <style>
        html {
          font-size: 62.5%;
        }
        body {
          font-family: sans-serif;
          background-color: rgb(51, 153, 255);
          color: white;
          display: flex;
          flex-direction: column;
          justify-content: center;
          height: 100vh;
        }
        div {
          text-align: center;
          font-size: 8rem;
          text-shadow: 3px 3px 4px dimgrey;
        }
      </style>
    </head>
    <body>
      <div>Hello from Xander!</div>
    </body>
    </html>
kind: ConfigMap
metadata:
  name: xander-html
  namespace: default
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: xander-nginx-ingress
spec:
  entryPoints:
    - web
  routes:
  - match: Path(`/xander`)
    kind: Rule
    services:
    - name: xander-nginx-service
      port: 80
    middlewares:
      - name: xander-stripprefix
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: xander-stripprefix
spec:
  stripPrefix:
    prefixes:
      - /xander
```

### Create configuration for server 1 - nginx-walter

Add the following content to nginx-walter.yaml:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: walter-nginx
  labels:
    app: walter-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: walter-nginx
  template:
    metadata:
      labels:
        app: walter-nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html-volume
        configMap:
          name: walter-html
---
apiVersion: v1
kind: Service
metadata:
  name: walter-nginx-service
spec:
  selector:
    app: walter-nginx
  ports:
    - protocol: TCP
      port: 80
---
apiVersion: v1
data:
  index.html: |-
    <html>
    <head><title>K3S!</title>
      <style>
        html {
          font-size: 62.5%;
        }
        body {
          font-family: sans-serif;
          background-color: rgb(131, 238, 109);
          color: white;
          display: flex;
          flex-direction: column;
          justify-content: center;
          height: 100vh;
        }
        div {
          text-align: center;
          font-size: 8rem;
          text-shadow: 3px 3px 4px dimgrey;
        }
      </style>
    </head>
    <body>
      <div>Hello from Walter!</div>
    </body>
    </html>
kind: ConfigMap
metadata:
  name: walter-html
  namespace: default
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: walter-nginx-ingress
spec:
  entryPoints:
    - web
  routes:
  - match: Path(`/walter`)
    kind: Rule
    services:
    - name: walter-nginx-service
      port: 80
    middlewares:
      - name: walter-stripprefix
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: walter-stripprefix
spec:
  stripPrefix:
    prefixes:
      - /walter
```

### Deploy and test the nginx-xander and nginx-walter

Deploy:

```bash
[macbook] $ kubectl apply -f nginx-xander.yaml
[macbook] $ kubectl apply -f nginx-walter.yaml
```

Open the web servers in a browser on:

* http://home.test.server.com/xander
* http://home.test.server.com/walter

Also, check that the Traefik-dashboard has middleware configurations.

# Part 3: Adding TLS-certificates to the Voyager-project

The purpose of this section is to build on the previous parts and add a TLS-certificate to the whoami-deployment.

## Self signed certificate

Self signed certificate:

```bash
$ openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout tls.key -out tls.crt -subj "/CN=home.test.server.com" -days 10
$ kubectl create secret tls home-test-server-com-tls --cert=tls.crt --key=tls.key
```



## Updating the whoami-project file:

Create a `whomi.yaml` file with the following content and deploy it and to access it added it to the /etc/hosts.

```yaml
# Who-am-i project
# * deployment
# * service
# * ingress (simple)
# based on:
# * https://github.com/traefik-workshops/traefik-workshop/tree/master/exercise-3
# * https://github.com/traefik-workshops/traefik-workshop/tree/master/exercise-4
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: whoami
  name: whoami
spec:
  replicas: 1
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - image: traefik/whoami:latest
          imagePullPolicy: IfNotPresent
          name: whoami
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami-svc
spec:
  type: ClusterIP
  selector:
    app: whoami
  ports:
    - port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami-http
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  tls:
    - secretName: home-test-server-com-tls
      hosts:
        - home.test.server.com
  rules:
    - host: home.test.server.com
      http:
        paths:
          - path: /whoami
            pathType: Exact
            backend:
              service:
                name: whoami-svc
                port:
                  number: 80
```

Deploy the configuration:

```bash
[macbook] $ kubectl apply -f whoami.yaml
```

This should give a tls/https.

# Part 4: Adding support for persistent volume

## NFS-share

* Create a virtual machine
* `sudo apt install nfs-kernel-server`

Serverside 192.168.56.10

```bash
sudo mkdir -p /mnt/nfs_share
sudo chown -R nobody:nogroup /mnt/nfs_share/
# add the following line for the whole subnet:
/mnt/nfs_share  192.168.56.0/24(rw,sync,no_subtree_check)
# For individual ip's:
# /mnt/nfs_share  client_IP_1 (re,sync,no_subtree_check)
# /mnt/nfs_share  client_IP_2 (re,sync,no_subtree_check)
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
# sudo ufw allow from 192.168.43.0/24 to any port nfs
# sudo ufw enable

```

Clientside

```bash
sudo apt update
sudo apt install nfs-common
sudo mkdir -p /mnt/nfs_clientshare
sudo mount 192.168.56.10:/mnt/nfs_share  /mnt/nfs_clientshare
```

## Longhorn

Commands used:

```bash
[master] $ kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.3/deploy/longhorn.yaml
[master] $ kubectl get pods \
--namespace longhorn-system \
--watch
# Output
NAME                                        READY   STATUS    RESTARTS        AGE
longhorn-ui-9fdb94f9-cqvpx                  1/1     Running   0               2m39s
longhorn-manager-t8vf5                      1/1     Running   0               2m40s
longhorn-driver-deployer-784546d78d-5pvvm   1/1     Running   0               2m39s
longhorn-manager-crf7t                      1/1     Running   1 (2m13s ago)   2m40s
instance-manager-r-b4c0e8c3                 1/1     Running   0               2m7s
instance-manager-r-bf80f472                 1/1     Running   0               2m11s
instance-manager-e-d33598e4                 1/1     Running   0               2m8s
instance-manager-e-84cce2e1                 1/1     Running   0               2m12s
engine-image-ei-fa2dfbf0-5zxrg              1/1     Running   0               2m11s
csi-attacher-5f46994f7-pzxw2                1/1     Running   0               100s
engine-image-ei-fa2dfbf0-cg7fn              1/1     Running   0               2m11s
csi-provisioner-6ccbfbf86f-gx675            1/1     Running   0               98s
csi-provisioner-6ccbfbf86f-4bhq5            1/1     Running   0               98s
longhorn-csi-plugin-t2n2f                   2/2     Running   0               96s
csi-attacher-5f46994f7-d7zkp                1/1     Running   0               100s
csi-resizer-6dd8bd4c97-kfsc5                1/1     Running   0               96s
csi-attacher-5f46994f7-gtjbc                1/1     Running   0               100s
csi-snapshotter-86f65d8bc-h4dtj             1/1     Running   0               96s
csi-provisioner-6ccbfbf86f-5m4fh            1/1     Running   0               98s
csi-resizer-6dd8bd4c97-h2879                1/1     Running   0               96s
csi-resizer-6dd8bd4c97-frjds                1/1     Running   0               96s
csi-snapshotter-86f65d8bc-rsgsl             1/1     Running   0               96s
longhorn-csi-plugin-mllbj                   2/2     Running   0               95s
csi-snapshotter-86f65d8bc-xpwdm             1/1     Running   0               96s	

$ kubectl -n longhorn-system get svc
#
NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
...
longhorn-frontend          ClusterIP   10.43.190.67    <none>        80/TCP      3m28s
...


K1032f3ef13f00b7074fbe9def31a6d9429d84df9e212bd3fd8aa9804a0ff4468f3::server:3c84c8e26487b74a177fe46ee31c0007

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.11 --flannel-iface=eth1" K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=K1032f3ef13f00b7074fbe9def31a6d9429d84df9e212bd3fd8aa9804a0ff4468f3::server:3c84c8e26487b74a177fe46ee31c0007  sh -



USER=michael; PASSWORD=michael; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
kubectl -n longhorn-system create secret generic basic-auth --from-file=auth

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # prevent the controller from redirecting (308) to HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: 'false'
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
    # custom max body size for file uploading like backing image uploading
    nginx.ingress.kubernetes.io/proxy-body-size: 10000m
spec:
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: longhorn-frontend
            port:
              number: 80


kubectl -n longhorn-system apply -f longhorn-ingress.yml

go to 192.168.56.10:80

volume claim from ui (but can be done from cli)

volume name: kubevol
pvc name: kubevol


Replicas of volumes must be 2??? not 3


apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # prevent the controller from redirecting (308) to HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: 'false'
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
    # custom max body size for file uploading like backing image uploading
    nginx.ingress.kubernetes.io/proxy-body-size: 10000m
    #
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - host: longhorn.test.server.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: longhorn-frontend
            port:
              number: 80
      - path: /lh(/|$)(.*)
        pathType: Exact
        backend:
          service:
            name: longhorn-frontend
            port:
              number: 80
```

