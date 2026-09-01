#!/usr/bin/env bash
# desc: Messaging: Slack, Telegram (via Flatpak)
set -euo pipefail
if ! command -v flatpak >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y flatpak
fi
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive flathub com.slack.Slack org.telegram.desktop
