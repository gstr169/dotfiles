#!/usr/bin/env bash
# Optional macOS defaults that affect terminal and editor work. Safe to re-run.
set -euo pipefail
[ "$(uname -s)" = Darwin ] || { echo "macos-defaults.sh: not macOS, skipping"; exit 0; }

defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
killall Finder >/dev/null 2>&1 || true
echo "macOS defaults applied (key repeat takes effect after logout)."
