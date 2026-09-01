#!/usr/bin/env bash
# desc: Browser and editors: Google Chrome, Sublime Text, JetBrains Toolbox, Enpass
set -euo pipefail
sudo install -d -m 0755 /etc/apt/keyrings

# Google Chrome
if ! command -v google-chrome >/dev/null; then
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg --yes
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
    | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
fi

# Sublime Text
if ! command -v subl >/dev/null; then
  curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/sublimehq-archive.gpg --yes
  echo "deb [signed-by=/etc/apt/keyrings/sublimehq-archive.gpg] https://download.sublimetext.com/ apt/stable/" \
    | sudo tee /etc/apt/sources.list.d/sublime-text.list >/dev/null
fi

# Enpass
if ! command -v enpass >/dev/null && [ ! -x /opt/enpass/Enpass ]; then
  curl -fsSL https://apt.enpass.io/keys/enpass-linux.key | sudo gpg --dearmor -o /etc/apt/keyrings/enpass.gpg --yes
  echo "deb [signed-by=/etc/apt/keyrings/enpass.gpg] https://apt.enpass.io/ stable main" \
    | sudo tee /etc/apt/sources.list.d/enpass.list >/dev/null
fi

sudo apt-get update -qq
sudo apt-get install -y google-chrome-stable sublime-text enpass

# JetBrains Toolbox (tarball; it self-updates afterwards)
TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"
if [ ! -x "$TOOLBOX_DIR/bin/jetbrains-toolbox" ]; then
  url="$(curl -fsSL 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' \
    | jq -r '.TBA[0].downloads.linux.link')"
  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/toolbox.tar.gz"
  mkdir -p "$TOOLBOX_DIR/bin"
  tar -xzf "$tmp/toolbox.tar.gz" -C "$tmp"
  cp "$tmp"/jetbrains-toolbox-*/jetbrains-toolbox "$TOOLBOX_DIR/bin/"
  rm -rf "$tmp"
  echo "JetBrains Toolbox extracted to $TOOLBOX_DIR/bin; run it once to finish setup."
fi
