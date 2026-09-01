#!/usr/bin/env bash
# Prepare a blank macOS or Debian/Ubuntu machine and run the dotfiles installer.
#   curl -fsSL https://raw.githubusercontent.com/gstr169/dotfiles/master/bootstrap.sh | bash
#   curl ... | bash -s -- --none --no-gui      # pass flags to ./install
set -euo pipefail

REPO_URL="https://github.com/gstr169/dotfiles.git"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

OS="$(uname -s)"
case "$OS" in
  Darwin) ;;
  Linux) [ -f /etc/debian_version ] || { echo "bootstrap: only Debian/Ubuntu Linux is supported" >&2; exit 1; } ;;
  *) echo "bootstrap: unsupported OS '$OS'" >&2; exit 1 ;;
esac

# --- 1. build prerequisites ---------------------------------------------------
if [ "$OS" = Darwin ]; then
  if ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools (a dialog will open)"
    xcode-select --install
    until xcode-select -p >/dev/null 2>&1; do sleep 10; done
  fi
else
  log "apt prerequisites"
  sudo apt-get update -qq
  if [ -f "$DOTFILES/apt-packages.txt" ]; then
    xargs -a "$DOTFILES/apt-packages.txt" sudo apt-get install -y
  else
    sudo apt-get install -y build-essential zsh git curl file procps ca-certificates gnupg nano
  fi
fi

# --- 2. homebrew ------------------------------------------------------------------
found=""
for p in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
  if [ -x "$p/bin/brew" ]; then eval "$("$p/bin/brew" shellenv)"; found=1; break; fi
done
if [ -z "$found" ]; then
  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for p in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [ -x "$p/bin/brew" ]; then eval "$("$p/bin/brew" shellenv)"; break; fi
  done
fi
command -v brew >/dev/null || { echo "bootstrap: Homebrew install failed" >&2; exit 1; }

# --- 3. repo ------------------------------------------------------------------------
self="${BASH_SOURCE[0]:-}"
if [ -n "$self" ] && [ "$(cd "$(dirname "$self")" 2>/dev/null && pwd -P)" = "$(cd "$DOTFILES" 2>/dev/null && pwd -P)" ]; then
  log "Running from inside $DOTFILES; not cloning"
elif [ -d "$DOTFILES/.git" ]; then
  log "Updating $DOTFILES"
  git -C "$DOTFILES" pull --ff-only --recurse-submodules
else
  log "Cloning to $DOTFILES"
  git clone --recurse-submodules "$REPO_URL" "$DOTFILES"
fi

# On Linux the apt list may not have existed before the clone; install it now.
if [ "$OS" = Linux ] && [ -f "$DOTFILES/apt-packages.txt" ]; then
  xargs -a "$DOTFILES/apt-packages.txt" sudo apt-get install -y -qq
fi

# --- 4. install ----------------------------------------------------------------------
exec "$DOTFILES/install" "$@"
