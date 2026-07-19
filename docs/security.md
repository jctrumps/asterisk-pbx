# Security notes

Asterisk and SIP are common scan targets. Treat any exposed SIP service as hostile-facing.

## Minimum checklist

- Use long random passwords for every extension.
- Do not expose `UDP/5060` to the public internet unless required.
- If remote phones are needed, prefer a VPN first.
- Restrict RTP to the smallest practical UDP range.
- Restrict firewall access to trusted LANs or SIP trunk provider IPs.
- Add Fail2ban before public exposure.
- Keep Proxmox, guest OS, Docker, and Asterisk images patched.
- Use Ansible Vault for extension passwords.
- Do not expose the Asterisk HTTP/ARI port, default `8088/tcp`, to untrusted networks.
- Use a long random ARI password and restrict ARI access to the internal AI service network.

## Suggested firewall policy

LAN-only lab:

```text
Allow from LAN to PBX VM: tcp/22
Allow from LAN to PBX VM: udp/5060
Allow from LAN to PBX VM: udp/10000-10100
Allow from AI VM to PBX VM: tcp/8088
Deny other inbound traffic
```

Public SIP trunk:

```text
Allow SIP provider IPs to PBX VM: udp/5060
Allow SIP provider IPs to PBX VM: udp/10000-10100
Deny internet-wide SIP scans
```
