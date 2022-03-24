# Docker tutorial

## Installation on Ubuntu server

Install required packages with `apt-get`:

```bash
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

Add Docker’s official GPG key:

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

Set up the **stable** repository (the ubuntu version shall be in the source list):

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Give the correct permissions to the keyring:

```bash
sudo chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg
```

Update `apt-get` and install `Docker`:

```bash
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io -y
```

Important (at least if Kubernetes is going to use Docker) give the user access:

```bash
sudo usermod -aG docker $USER && newgrp docker
```

Check that Docker works:

```bash
docker version
```
