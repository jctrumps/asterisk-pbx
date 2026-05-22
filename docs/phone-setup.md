# Phone and softphone setup

Use the PBX VM IP address as the SIP server.

Example for extension `1001`:

```text
Account name:      1001
SIP username:      1001
Auth username:     1001
Password:          from group_vars/asterisk_vault.yml
Domain/server:     192.168.1.50
Proxy:             leave blank for LAN use
Transport:         UDP
Port:              5060
STUN:              off for LAN use
```

## Test numbers

```text
600 = echo test
700 = hello-world playback
1001 calls extension 1001
1002 calls extension 1002
```

## Useful Asterisk CLI commands

```bash
sudo docker exec -it asterisk asterisk -rvvv
pjsip show endpoints
pjsip show contacts
core show channels
rtp set debug on
rtp set debug off
```
