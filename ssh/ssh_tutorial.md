# ssh tutorial

## Install on ubuntu

```bash
sudo apt install openssh
```

## Generate key-pair and upload to server

```bash
# Generate key-pair (RSA encryption)
ssh-keygen -t rsa -b 4096

# Generate key-pair (ed25519 encryption standard)
sh-keygen -t ed25519

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_rsa <user>@<ip-address>
```

## Logon server using ssh

```bash
ssh <user-name>@<ip-address>
```

