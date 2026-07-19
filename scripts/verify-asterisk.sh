#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${ASTERISK_CONTAINER_NAME:-asterisk}"
EXPECTED_VERSION="${ASTERISK_EXPECTED_VERSION:-22.10.1}"
EXPECTED_QUEUE="${ASTERISK_EXPECTED_QUEUE:-human-fallback}"
EXPECTED_STASIS_APP="${ASTERISK_EXPECTED_STASIS_APP:-voice-ai-agent}"

run_ast() {
  sudo docker exec "$CONTAINER_NAME" asterisk -rx "$1"
}

require_output() {
  local description="$1"
  local command="$2"
  local pattern="$3"

  printf '== %s ==\n' "$description"
  local output
  output="$(run_ast "$command")"
  printf '%s\n' "$output"
  if ! printf '%s\n' "$output" | grep -Eq "$pattern"; then
    printf 'FAILED: %s\n' "$description" >&2
    exit 1
  fi
}

printf '== Docker health ==\n'
sudo docker ps --filter "name=^/${CONTAINER_NAME}$"
sudo docker inspect --format='{{json .State.Health}}' "$CONTAINER_NAME"

require_output "Asterisk version" "core show version" "Asterisk ${EXPECTED_VERSION}"
require_output "Asterisk uptime" "core show uptime" "System uptime:|Last reload:"
require_output "PJSIP endpoints" "pjsip show endpoints" "Endpoint: +1001/1001|Endpoint: +1002/1002"
require_output "chan_websocket loaded" "module show like chan_websocket" "chan_websocket\.so"
require_output "HTTP WebSocket loaded" "module show like res_http_websocket" "res_http_websocket\.so"
require_output "ARI loaded" "module show like res_ari" "res_ari\.so"
require_output "Stasis loaded" "module show like stasis" "app_stasis\.so|res_stasis\.so"
require_output "HTTP status" "http show status" "Server Enabled and Bound|Enabled URI"
require_output "ARI status" "ari show status" "Asterisk REST Interface|Enabled"
require_output "Dialplan 600" "dialplan show 600@internal" "Echo"
require_output "Dialplan 700" "dialplan show 700@internal" "Playback\(hello-world\)"
require_output "Dialplan 800" "dialplan show 800@internal" "Stasis\(${EXPECTED_STASIS_APP}\)"
require_output "Dialplan 0" "dialplan show 0@internal" "human-fallback"
require_output "Fallback queue" "queue show ${EXPECTED_QUEUE}" "${EXPECTED_QUEUE}"
require_output "Voicemail users" "voicemail show users" "1001"

printf 'All Asterisk PBX verification checks passed.\n'
