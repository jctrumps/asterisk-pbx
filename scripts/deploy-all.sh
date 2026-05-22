#!/usr/bin/env bash
set -euo pipefail

"$(dirname "$0")/deploy-infra.sh"
"$(dirname "$0")/deploy-app.sh"
