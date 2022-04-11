# High availability Kubernetes cluster

The setting up of the cluster involves the following **overall steps and processes**:

1. My [**Proxmox server**](proxmox-server.md) setup
2. **[Loadbalancer](HAproxy_loadbalancer.md)** - which will be the entry point for trafic to services provided by the cluster
   * Install HAproxy
   * Configure `/etc/haproxy/haproxy.cfg` to send traffic to the cluster
   * After configuration, restart `haproxy` with `systemctl`
   * Configure `Sysctl` for Kubernetes networking
3. **[Prepare all nodes](prepare_server_for_cluster_node.md)**, master and worker nodes, which can be done relatively fast using syncronisation in `tmux`
   * Disable firewall (or at least open the right ports)
   * Turn off swap and make it permanent
   * Install with the apt-packet manager: `ca-certificates`, `curl`, `gnupg`, `lsb-release`, and `apt-transport-https`
   * Install (from repository specified below): `docker-ce`, `docker-ce-cli`, and `containerd.io`
   * Configure `containerd.conf` [test if really needed]
   * Configure `/etc/docker/daemon.json`
   * Start and enable`docker` in `systemctl`
   * Configure `modprobe` (overlay and br_netfilter)
   * Setup required `sysctl` params for `/etc/sysctl.d/99-kubernetes-cri.conf`
   * Add Kubernetes repository to the package manager
   * Install `kubeadm`
   * Install `helm`
4. [**Initialise** and **join nodes**](initialize_join_nodes.md)  with `kubeadm init` and `kubeadm join`
5. Now **just use the cluster** for what you need
