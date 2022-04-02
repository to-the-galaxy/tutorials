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
