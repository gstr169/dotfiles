#!/usr/bin/env bash
# Print cask tokens (space separated) from the given Brewfiles whose .app already
# exists in /Applications but is NOT managed by brew. ./install exports the result
# as HOMEBREW_BUNDLE_CASK_SKIP so `brew bundle` does not fail on hand-installed apps.
set -euo pipefail

tokens="$(grep -hE '^cask ' "$@" | sed -E 's/^cask "([^"]+)".*/\1/' | sort -u | tr '\n' ' ')"
[ -n "${tokens// /}" ] || exit 0

installed="$(brew list --cask 2>/dev/null || true)"
skip=()
while IFS=$'\t' read -r token app; do
  [ -n "$app" ] || continue
  grep -qx "$token" <<<"$installed" && continue
  [ -e "/Applications/$app" ] && skip+=("$token")
done < <(brew info --cask --json=v2 $tokens 2>/dev/null \
  | jq -r '.casks[] | "\(.token)\t\([.artifacts[] | .app? // empty | .[0]? // empty | strings] | first // "")"')

echo "${skip[*]:-}"
