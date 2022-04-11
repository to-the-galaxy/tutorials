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

**Warning** regarding kubernetes configuration file being group-readable and/or world-readable.

```bash
chmod go-r ~/.kube/config
```
