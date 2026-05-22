#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../opentofu"
tofu init
tofu apply
