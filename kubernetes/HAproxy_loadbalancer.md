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

```
global
	log /dev/log	local0
	log /dev/log	local1 notice
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
	stats timeout 30s
	user haproxy
	group haproxy
	daemon

	# Default SSL material locations
	ca-base /etc/ssl/certs
	crt-base /etc/ssl/private

	# See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
	log	global
	mode	http
	option	httplog
	option	dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
	errorfile 400 /etc/haproxy/errors/400.http
	errorfile 403 /etc/haproxy/errors/403.http
	errorfile 408 /etc/haproxy/errors/408.http
	errorfile 500 /etc/haproxy/errors/500.http
	errorfile 502 /etc/haproxy/errors/502.http
	errorfile 503 /etc/haproxy/errors/503.http
	errorfile 504 /etc/haproxy/errors/504.http

frontend Local_Server
    # bind 192.168.100.102:80
    bind *:80
    mode http
    default_backend k8s_server

frontend Local_Server_Api
    # bind 192.168.100.102:80
    bind *:6443
    mode tcp
    default_backend k8s_server_api

backend k8s_server
    mode http
    balance roundrobin
    # server k8s-api-1 192.168.1.101:8080 check
    # server k8s-api-2 192.168.1.102:8080 check
    # server k8smaster1 192.168.100.124:6443 check fall 3 rise 2
    # server k8smaster1 192.168.100.124:8080
    # server k8smaster1 192.168.100.124:80 check fall 3 rise 2
    # server k8smaster2 192.168.100.195:80 check fall 3 rise 2
    server k8smaster1 192.168.100.240:80

backend k8s_server_api
    mode tcp
    balance roundrobin
    # server k8s-api-1 192.168.1.101:8080 check
    # server k8s-api-2 192.168.1.102:8080 check
    # server k8smaster1 192.168.100.124:6443 check fall 3 rise 2
    server k8smaster1 192.168.100.124:6443
    server k8smaster2 192.168.100.195:6443
    ```