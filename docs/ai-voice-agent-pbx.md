# AI voice-agent PBX integration

## Scope

This document covers only the Asterisk PBX-side integration points for a separate AI voice-agent service.

The AI inference VM, Hailo runtime, speech-to-text, language model, text-to-speech, databases, and application workflow are intentionally outside this PBX repo.

## PBX responsibilities

The PBX provides:

- Asterisk 22 or newer built into the container image
- PJSIP extensions and future trunk support
- HTTP and ARI enabled for an internal AI service
- Stasis entry point for AI-owned calls
- WebSocket-capable Asterisk modules, including `chan_websocket`
- G.711 u-law phone support and signed-linear media support for ARI External Media
- human fallback via extension `0`
- queue and voicemail fallback when the AI service is unavailable

## Default internal call flow

```text
Phone or SIP call
    -> Asterisk internal context
    -> extension 800
    -> Stasis app voice-ai-agent
    -> external AI service over ARI/WebSocket media
    -> caller
```

If the ARI app is unavailable or exits, the dialplan routes the call to human fallback:

```text
AI unavailable
    -> human-fallback queue
    -> voicemail fallback
```

## Important extensions

```text
0   = human fallback queue
600 = echo test
700 = hello-world playback
800 = AI voice-agent Stasis entry point
```

## ARI defaults

Defaults live in `ansible/group_vars/asterisk.yml`:

```yaml
asterisk_ari_enabled: true
asterisk_ari_username: "voice_ai"
asterisk_ari_allowed_origins: "http://10.10.10.60:8000"
asterisk_ai_extension: "800"
asterisk_ai_stasis_app: "voice-ai-agent"
asterisk_operator_extension: "0"
asterisk_http_bind: "0.0.0.0"
asterisk_http_port: 8088
```

The ARI password must be set in local-only vault data:

```yaml
asterisk_ari_password: "replace-with-a-long-random-ari-password"
```

The playbook intentionally fails if the ARI password is still a placeholder.

## Local vault requirements

Copy the example file:

```bash
cp ansible/group_vars/asterisk_vault.yml.example ansible/group_vars/asterisk_vault.yml
```

Set real local values for:

- `asterisk_extensions[*].password`
- `asterisk_ari_password`
- `asterisk_voicemail_mailboxes[*].password`

Do not commit `ansible/group_vars/asterisk_vault.yml`.

## Health and verification commands

From the PBX VM shell:

```bash
sudo docker exec asterisk asterisk -rx "core show version"
sudo docker exec asterisk asterisk -rx "http show status"
sudo docker exec asterisk asterisk -rx "ari show status"
sudo docker exec asterisk asterisk -rx "module show like websocket"
sudo docker exec asterisk asterisk -rx "module show like stasis"
sudo docker exec asterisk asterisk -rx "queue show human-fallback"
```

From the Asterisk CLI:

```text
pjsip show endpoints
pjsip show contacts
ari show status
http show status
queue show human-fallback
```

## Security notes

ARI can control calls. Treat it as an internal control-plane API.

- Do not expose `8088/tcp` to the internet.
- Restrict `8088/tcp` to the AI service VM or trusted management subnet.
- Use a long random ARI password.
- Rotate the ARI password before production use.
- Keep AI business logic outside Asterisk; Asterisk should route calls, not decide business actions.

## AI app contract

The external AI service should connect to ARI and subscribe to the configured Stasis app name:

```text
voice-ai-agent
```

The AI service is responsible for:

- creating ARI External Media channels when needed
- VAD, STT, LLM, TTS, and barge-in behavior
- validating model outputs before business actions
- transferring to extension `0` or another approved fallback path when confidence is low or the caller requests a human

The PBX remains functional when the AI service is offline because extension `800` falls through to the human fallback dialplan.
