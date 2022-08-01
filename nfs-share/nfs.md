# NFS-share and Synology

## Setup Synology

- Activate NFS:
  - Control Panel > File Services > NFS
  - Activate NFS
- Make a share or folder accessible over the NFS-protocol
  - Contol Panel > Shared Folder > [Select the relevant folder] > Edit
  - Edit folder window > NFS-Permissions
  - Click "Create" to create an NFS-rule
  - NFS-rule parameters:
    - Hostename or IP: `192.168.100.192/24`
    - Privilege: `Read/Write`
    - Squash: `Map all users to admin`
    - Security: `sys`
    - Enable asynchronous: Yes
    - Allow connections from non-privileged ports (ports higher than 1024): Yes
    - Allow users to access mounted subfolders: Yes

## Connect to NFS-share (client-side) on Linux

- Install `nfs-commons`
- Create a folder to which the NFS-share shall be mounted, for example: `/mnt/nfs/`
- Mount command: `sudo mount -t nfs 192.168.100.100:/volume3/photography /mnt/nfs`

## Troubleshooting

It may be necessary to activate the NFS on the Synology several times. Even, turn off the NFS and re-activate it.