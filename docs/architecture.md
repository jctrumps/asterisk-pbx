# Architecture

## Layer ownership

```text
OpenTofu
  Owns: VM lifecycle, Proxmox resources, CPU/RAM/disk/NIC, cloud-init, SSH bootstrap.

Ansible
  Owns: OS packages, Docker installation, directories, rendered configs, Compose deployment.

Docker Compose
  Owns: Asterisk container lifecycle on the VM.

Asterisk
  Owns: PJSIP endpoints, dialplan, RTP range, call routing.

Phones
  Own: registration to the PBX VM IP.
```

## Why a dedicated VM?

A dedicated VM keeps Docker networking, PBX ports, logs, and security controls away from the Proxmox host. Docker host networking only applies inside that VM.

## Network flow

```text
Phone/Softphone             PBX VM                    Asterisk container
10.10.10.x    --->   10.10.10.50:5060/UDP   --->   network_mode: host
              <---   UDP/10000-10100 RTP     <---
```

## Default ports

```text
22/tcp            SSH/Ansible
5060/udp          SIP signaling
10000-10100/udp   RTP media
```
