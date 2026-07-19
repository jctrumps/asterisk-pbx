# PBX firewall guidance

## Scope

This repository does not automatically configure a firewall. Firewall rules depend on the real phone, management, SIP trunk, and AI service networks.

Use this document as a starting point before exposing the PBX beyond a trusted lab network.

## Default exposed services

```text
22/tcp            SSH and Ansible
5060/udp          SIP signaling
10000-10100/udp   RTP media
8088/tcp          Asterisk HTTP and ARI
```

## Recommended policy

Default-deny inbound traffic, then allow only required sources.

Example only:

```bash
sudo ufw default deny incoming
sudo ufw allow from 10.10.10.0/24 to any port 5060 proto udp
sudo ufw allow from 10.10.10.0/24 to any port 10000:10100 proto udp
sudo ufw allow from 10.10.10.10 to any port 22 proto tcp
sudo ufw allow from 10.10.10.60 to any port 8088 proto tcp
sudo ufw enable
```

Replace the example addresses before use.

## ARI hardening

ARI can control calls. Treat `8088/tcp` as an internal control-plane API.

- Do not expose `8088/tcp` to the public internet.
- Allow `8088/tcp` only from the AI service VM or a trusted management host.
- Use a long random `asterisk_ari_password` in `ansible/group_vars/asterisk_vault.yml`.
- Use TLS or a trusted private network before production use.
