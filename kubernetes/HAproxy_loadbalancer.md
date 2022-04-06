## Setup a HAproxy as Loadbalancer

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

