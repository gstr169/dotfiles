#!/usr/bin/env bash
# desc: Network: Tailscale
set -euo pipefail
if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
echo "Run 'sudo tailscale up' to sign in."
