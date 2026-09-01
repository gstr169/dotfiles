#!/usr/bin/env bash
# Print cask tokens (space separated) from the given Brewfiles that are already
# present on the machine but NOT managed by brew: either the .app exists in
# /Applications (by artifact or by cask display name, which covers App Store
# installs), or (for pkg-based casks) the pkg receipt is registered.
# ./install exports the result as HOMEBREW_BUNDLE_CASK_SKIP so `brew bundle`
# does not fail on hand-installed apps.
set -euo pipefail

tokens="$(grep -hE '^cask ' "$@" | sed -E 's/^cask "([^"]+)".*/\1/' | sort -u | tr '\n' ' ')"
[ -n "${tokens// /}" ] || exit 0

installed="$(brew list --cask 2>/dev/null || true)"
skip=()
while IFS='|' read -r token app pkgid name; do
  grep -qx "$token" <<<"$installed" && continue
  if [ -n "$app" ] && [ -e "/Applications/$app" ]; then
    skip+=("$token")
  elif [ -n "$name" ] && [ -e "/Applications/$name.app" ]; then
    skip+=("$token")
  elif [ -n "$pkgid" ] && pkgutil --pkg-info "$pkgid" >/dev/null 2>&1; then
    skip+=("$token")
  fi
done < <(brew info --cask --json=v2 $tokens 2>/dev/null | jq -r '
  .casks[] |
  "\(.token)|\([.artifacts[] | .app? // empty | .[0]? // empty | strings] | first // "")|\([.artifacts[] | .uninstall? // empty | .[] | .pkgutil? // empty | (if type == "array" then .[0] else . end) | strings] | first // "")|\(.name[0] // "")"')

echo "${skip[*]:-}"
