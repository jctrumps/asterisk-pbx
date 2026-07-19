# Asterisk 22 PBX Verification and Hardening Plan

## Purpose

This document records the post-upgrade status of the Asterisk PBX project and defines the remaining work for the `pbx-1` VM.

The scope of this repository is limited to:

- Proxmox VM provisioning for `pbx-1`
- Guest configuration
- Docker and Docker Compose
- Asterisk
- PJSIP extensions and future SIP trunks
- SIP and RTP handling
- HTTP and ARI configuration
- Stasis and WebSocket media support
- Call routing
- Human queue and voicemail fallback
- PBX security, validation, and operations

The external AI application, inference hardware, speech recognition, language model, text-to-speech, databases, and application workflow belong in a separate project and are not part of this repository.

---

## Current Status

| Area | Status | Evidence |
|---|---|---|
| Proxmox VM provisioning | Passed | OpenTofu completed successfully on `pve-minibox-01` |
| Guest configuration | Passed | Ansible completed successfully |
| Asterisk container build | Passed | Asterisk 22 image built and started |
| PJSIP endpoint registration | Passed | Extensions `1001` and `1002` registered |
| Internal SIP calling | Passed | Successful call from `1001` to `1002` |
| RTP audio | Passed | Two-way audio worked during the extension call |
| ARI configuration | Present, runtime verification required | ARI templates and credentials are configured |
| Stasis entry point | Present, runtime verification required | Extension `800` enters `voice-ai-agent` |
| WebSocket media modules | Enabled at build time, runtime verification required | Dockerfile enables the required modules |
| Human fallback | Configured, runtime verification required | Extension `0`, queue, and voicemail are configured |
| Production security | Incomplete | ARI firewall restrictions and optional TLS remain |

Implementation decisions now recorded in the repo:

- `asterisk_version` is pinned to `22.10.1`.
- The Asterisk HTTP prefix is removed; ARI is expected at `/ari`.
- `/opt/asterisk-pbx/scripts/verify-asterisk.sh` provides non-secret runtime verification checks after deployment.
- `docs/firewall.md` documents the PBX-side firewall policy template.

---

## Repository Boundary

The `asterisk-pbx` repository owns the PBX-side contract only.

It must provide:

- A supported Asterisk release
- PJSIP registration and call routing
- ARI access for an approved internal client
- A Stasis application entry point
- WebSocket-capable Asterisk modules
- External Media support
- An internal AI dialplan extension
- Human transfer and voicemail fallback
- Safe behavior when no ARI application is connected
- PBX logs, health checks, and operator documentation

It must not contain:

- Hailo drivers or HailoRT
- PCIe accelerator provisioning
- Speech-to-text services
- Language models
- Text-to-speech services
- AI prompts or business logic
- AI call-state orchestration
- AI databases
- Model-specific Docker services

Those components belong in the separate `voice-ai` project.

---

## Required Follow-Up Work

### 1. Document the Correct Minimum Asterisk Version

The AI-facing PBX integration depends on `chan_websocket`.

All relevant documentation should state:

```text
Asterisk 22.6.0 or newer
```

Do not describe every Asterisk 22 release as supporting the required WebSocket channel driver.

#### Files reviewed

- `README.md`
- `docs/ai-voice-agent-pbx.md`
- Any architecture, deployment, or upgrade documentation that previously said only “Asterisk 22 or newer”

#### Acceptance criteria

- Every AI-facing PBX document states `Asterisk 22.6.0 or newer`.
- No document implies that early Asterisk 22 releases include `chan_websocket`.

Official reference:

- <https://docs.asterisk.org/Configuration/Channel-Drivers/WebSocket/>

---

### 2. Decide How to Handle the Asterisk HTTP Prefix

The repository removes the Asterisk HTTP prefix. ARI is located at the usual path:

```text
http://<pbx-ip>:8088/ari
```

This keeps ARI and WebSocket paths predictable for the external AI service.

Update:

```text
ansible/roles/asterisk/templates/http.conf.j2
```

Recommended configuration:

```ini
; Managed by Ansible. Do not edit directly on the VM.

[general]
enabled={{ 'yes' if asterisk_ari_enabled | bool else 'no' }}
bindaddr={{ asterisk_http_bind }}
bindport={{ asterisk_http_port }}
tlsenable=no
```

#### Acceptance criteria

- The prefix is removed and ARI works at `/ari`.
- PBX documentation consistently uses the unprefixed ARI URL.

Official reference:

- <https://docs.asterisk.org/Configuration/Interfaces/Asterisk-REST-Interface-ARI/Asterisk-Configuration-for-ARI/>

---

### 3. Restrict ARI and HTTP Access

ARI can control live calls and must be treated as an internal control-plane API.

The current defaults bind Asterisk HTTP to all VM interfaces:

```yaml
asterisk_http_bind: "0.0.0.0"
asterisk_http_port: 8088
```

The `allowed_origins` setting controls browser CORS behavior. It does not replace a network firewall and does not restrict ordinary API clients by source IP.

#### Lab requirement

Allow TCP port `8088` only from:

- The approved internal ARI client address or subnet
- A trusted administration address or subnet, when required

Do not expose TCP `8088` to the public internet.

#### Recommended implementation options

Use one or more of:

- Proxmox firewall rules for `pbx-1`
- Guest firewall rules using `nftables` or `ufw`
- A dedicated private network for PBX control traffic
- TLS for ARI and WebSocket traffic before production use

#### Example guest firewall policy

Replace all example addresses before use:

```bash
sudo ufw default deny incoming
sudo ufw allow from <approved-ari-client-ip> to any port 8088 proto tcp
sudo ufw allow from <phone-network> to any port 5060 proto udp
sudo ufw allow from <phone-network> to any port 10000:10100 proto udp
sudo ufw allow from <management-ip-or-subnet> to any port 22 proto tcp
sudo ufw enable
```

Do not apply example firewall rules without first confirming the actual phone, management, SIP-provider, and ARI-client networks.

#### Acceptance criteria

- TCP `8088` is unreachable from untrusted networks.
- The approved internal ARI client can reach the ARI endpoint.
- The ARI password remains stored only in the ignored local vault file.
- The production design uses TLS or an explicitly documented trusted private network.

---

### 4. Pin an Exact Asterisk Version

The current default uses a pinned release:

```yaml
asterisk_version: "22.10.1"
```

The repository briefly used a moving 22 release during the upgrade, but it now pins an exact release for reproducible builds.

#### Required action

Determine the exact running version:

```bash
sudo docker exec asterisk asterisk -rx "core show version"
```

If a newer release is validated later, update:

```text
ansible/group_vars/asterisk.yml
```

Example:

```yaml
asterisk_version: "22.10.1"
```

Use the exact version reported by the validated deployment.

#### Acceptance criteria

- `asterisk_version` contains an exact release number.
- The pinned release is at least `22.6.0`.
- A clean rebuild downloads the same Asterisk source release.
- The exact version is recorded in the deployment documentation.

---

### 5. Verify Required Modules at Runtime

The Dockerfile enables the required modules during compilation, but the running container must also load them successfully.

Required modules include:

```text
chan_websocket.so
res_http_websocket.so
res_ari.so
app_stasis.so
```

Additional ARI and Stasis dependency modules should load automatically.

#### Acceptance criteria

- Each required module is reported as loaded.
- There are no unresolved dependency errors in the Asterisk logs.
- Asterisk starts cleanly after a container restart.

---

### 6. Validate the PBX Dialplan Boundary

The PBX must expose predictable internal call paths:

```text
0   = human fallback
600 = echo test
700 = hello-world playback
800 = Stasis entry point
```

The PBX remains responsible for routing and fallback. It does not perform AI inference or business decisions.

#### Acceptance criteria

- Extension `800` enters `Stasis(voice-ai-agent)`.
- If the Stasis application is unavailable or returns control, the call proceeds to PBX fallback.
- Extension `0` enters the human fallback queue.
- Queue timeout reaches the configured voicemail mailbox.
- Normal extension-to-extension calling remains unaffected.

---

## Runtime Verification Checklist

Run the following commands from the `pbx-1` VM.

### Core version and container health

```bash
sudo docker ps
sudo docker inspect --format='{{json .State.Health}}' asterisk
sudo docker exec asterisk asterisk -rx "core show version"
sudo docker exec asterisk asterisk -rx "core show uptime"
```

Expected result:

- The `asterisk` container is running and healthy.
- The reported version matches the pinned Ansible value.

### PJSIP endpoints and contacts

```bash
sudo docker exec asterisk asterisk -rx "pjsip show endpoints"
sudo docker exec asterisk asterisk -rx "pjsip show contacts"
```

Expected result:

- Extensions `1001` and `1002` are listed.
- Registered devices have reachable contacts.

### Required modules

```bash
sudo docker exec asterisk asterisk -rx "module show like chan_websocket"
sudo docker exec asterisk asterisk -rx "module show like res_http_websocket"
sudo docker exec asterisk asterisk -rx "module show like res_ari"
sudo docker exec asterisk asterisk -rx "module show like stasis"
```

Expected result:

- `chan_websocket.so` is loaded.
- `res_http_websocket.so` is loaded.
- ARI modules are loaded.
- Stasis modules and applications are loaded.

### HTTP and ARI

```bash
sudo docker exec asterisk asterisk -rx "http show status"
sudo docker exec asterisk asterisk -rx "ari show status"
```

Expected result:

- The HTTP server is enabled on the intended interface and port.
- ARI is enabled.
- The `voice_ai` user is available.
- The displayed URI paths match the documented prefix decision.

### Dialplan

```bash
sudo docker exec asterisk asterisk -rx "dialplan show 600@internal"
sudo docker exec asterisk asterisk -rx "dialplan show 700@internal"
sudo docker exec asterisk asterisk -rx "dialplan show 800@internal"
sudo docker exec asterisk asterisk -rx "dialplan show 0@internal"
```

Expected result:

- `600` enters the echo test.
- `700` plays the hello-world audio.
- `800` enters `Stasis(voice-ai-agent)`.
- `0` routes to the human fallback path.

### Queue and voicemail fallback

```bash
sudo docker exec asterisk asterisk -rx "queue show human-fallback"
sudo docker exec asterisk asterisk -rx "voicemail show users"
```

Expected result:

- The human fallback queue exists.
- The expected queue member is listed.
- The fallback voicemail mailbox exists.

### Logs

```bash
sudo docker logs --tail 200 asterisk
sudo tail -n 200 /opt/asterisk-pbx/log/full
```

Expected result:

- No required module fails to load.
- No repeated ARI, HTTP, PJSIP, RTP, queue, or voicemail errors appear.
- Container startup completes normally.

---

## Functional Test Plan

### Test 1: Extension calling

1. Register extension `1001`.
2. Register extension `1002`.
3. Call `1002` from `1001`.
4. Call `1001` from `1002`.
5. Confirm two-way audio and clean hangup behavior.

Current status:

- `1001` to `1002`: **Passed**

### Test 2: Echo service

1. Dial `600`.
2. Speak for at least ten seconds.
3. Confirm the caller hears returned audio without excessive delay or distortion.

### Test 3: Playback service

1. Dial `700`.
2. Confirm the hello-world prompt plays.
3. Confirm the channel hangs up normally afterward.

### Test 4: Human fallback

1. Dial `0`.
2. Confirm the configured queue member rings.
3. Allow the queue timeout to expire.
4. Confirm the call reaches the configured voicemail mailbox.

### Test 5: Stasis unavailable fallback

Perform this test while no external Stasis application is connected:

1. Dial `800`.
2. Confirm Asterisk attempts to enter `voice-ai-agent`.
3. Confirm the dialplan proceeds to `ai-unavailable` when the application is unavailable or releases the channel.
4. Confirm the call enters the human queue.
5. Confirm voicemail is offered after the queue timeout.

### Test 6: ARI authentication

Use the unprefixed ARI URL:

```bash
curl -u 'voice_ai:<ari-password>' \
  http://<pbx-ip>:8088/ari/asterisk/info
```

Expected result:

- Valid credentials return Asterisk information.
- Invalid credentials are rejected.
- Untrusted source networks cannot connect to TCP `8088`.

Do not place the real ARI password in shell history, screenshots, committed scripts, or documentation.

---

## Recommended Repository Changes

Files to review or modify:

```text
README.md
docs/ai-voice-agent-pbx.md
docs/asterisk-22-pbx-verification-and-hardening-plan.md
ansible/group_vars/asterisk.yml
ansible/group_vars/asterisk_local.yml.example
ansible/roles/asterisk/templates/http.conf.j2
```

Optional PBX-only additions:

```text
docs/firewall.md
scripts/verify-asterisk.sh
```

`scripts/verify-asterisk.sh` is the tracked source copy. Ansible deploys it to `/opt/asterisk-pbx/scripts/verify-asterisk.sh` on the PBX VM. The script runs non-secret PBX checks and fails when required modules, endpoints, dialplan entries, queues, voicemail, HTTP, or ARI status are missing.

---

## Definition of Done

The Asterisk PBX upgrade is complete when all of the following are true:

- OpenTofu can create or reconcile `pbx-1`.
- Ansible completes without errors.
- The Asterisk container is healthy.
- The project pins an exact Asterisk release at or above `22.6.0`.
- Extensions `1001` and `1002` register and can call each other.
- Echo and playback test extensions work.
- `chan_websocket`, HTTP WebSocket, ARI, and Stasis modules are loaded.
- ARI authentication succeeds from an approved source.
- TCP `8088` is blocked from untrusted networks.
- The HTTP prefix behavior is intentional and documented.
- Extension `0` reaches the human fallback queue.
- Queue timeout reaches voicemail.
- Extension `800` falls back safely while no Stasis application is connected.
- Asterisk restarts cleanly without required-module errors.
- No real secrets, state files, generated inventory, or local-only overrides are committed.
- Repository documentation matches the generated PBX configuration.

---

## External Integration Contract

The separate external project may connect to the PBX using the following interface:

```text
ARI username: configured by asterisk_ari_username
ARI password: supplied through the local Ansible vault
ARI application: voice-ai-agent
Dialplan entry: 800
Human fallback: 0
HTTP/ARI port: 8088
Media support: chan_websocket and ARI External Media
```

The PBX repository owns this interface and its fallback behavior only. All external application implementation remains outside this repository.
