# Proxmox server setup

All components in the cluste will be runing on Ubuntu 20.24 servers. The servers themselves are runing as virtual machines on a Intel NUC running Proxmox 7.

**Summary** of servers, IP addresses, DNS-names, and applications: 

| Type         | Name (server)   | Ip                   | DNS                          | Applications                                        |
| ------------ | --------------- | -------------------- | ---------------------------- | --------------------------------------------------- |
| Loadbalancer | k8sloadbalancer | 192.168.100.102      | k8sloadbalancer.proxmox.home | Haproxy (and kubectl but it is probably not needed) |
| master node  | k8smaster1      | 192.168.100.124      | k8smaster1.proxmox.home      | Kubectl, Kubeadm, Helm and Metal                    |
| master node  | k8smaster2      | 192.168.100.195      | k8smaster2.proxmox.home      | [to be joined as a master]                          |
| worker node  | k8sworker1      | 192.168.100.118      | k8sworker1.proxmox.home      | [to be joined as a worker]                          |
| cidr         | -               | 10.244.0.0/16        | -                            | [???]                                               |
| DNS          | -               | 192.168.100.101:8000 | -                            | PiHole also on in a small cluster                   |

After creation of the servers, a public ssh-key is copied to each of them, so that it is easy to access them:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub <user-name>@<ip-address>
```

Update all packages on all servers:

```bash
sudo apt update && sudo apt upgrade -y
```

