#!/usr/bin/env bash
# Post-install assertions. Runs zsh inside a pseudo-terminal so powerlevel10k
# and gitstatus behave as in a real terminal. Exit 0 = all good.
set -uo pipefail

fail() { printf '\033[1;31mFAIL\033[0m %s\n' "$*"; exit 1; }
ok()   { printf '\033[1;32mok\033[0m   %s\n' "$*"; }

expect_email="${DOTFILES_EXPECT_EMAIL:-dmit.finn@yandex.ru}"
errfile="$(mktemp)"
trap 'rm -f "$errfile"' EXIT

# run_zsh CMD: run CMD in an interactive login zsh under a pty; stderr goes to $errfile.
# A wrapper script avoids nested quoting; `script` differs between BSD (macOS) and util-linux.
run_zsh() {
  local wrapper; wrapper="$(mktemp)"
  printf '#!/usr/bin/env bash\nzsh -ilc %q 2>%q\n' "$1" "$errfile" > "$wrapper"
  chmod +x "$wrapper"
  if [ "$(uname -s)" = Darwin ]; then
    script -q /dev/null "$wrapper" >/dev/null
  else
    script -qec "$wrapper" /dev/null >/dev/null
  fi
  rm -f "$wrapper"
}

# 1. Startup produces no stderr output.
run_zsh 'exit'
if [ -s "$errfile" ]; then
  echo "--- zsh stderr ---"; cat "$errfile"; echo "------------------"
  fail "zsh startup wrote to stderr"
fi
ok "zsh starts silently"

# 2. Required commands resolve inside the configured shell.
missing="$(zsh -ilc 'for c in fzf eza bat rg fd zoxide uv pyenv micro lazygit git; do command -v "$c" >/dev/null || printf "%s " "$c"; done' 2>/dev/null)"
[ -z "$missing" ] || fail "missing on PATH inside zsh: $missing"
ok "required commands on PATH"

# 3. EDITOR is micro or nano.
editor="$(zsh -ilc 'echo $EDITOR' 2>/dev/null | tail -1)"
case "$editor" in micro|nano) ok "EDITOR=$editor" ;; *) fail "EDITOR is '$editor', expected micro or nano" ;; esac

# 4. Git identity: personal by default, placeholder under ~/projects/argo/.
[ "$(git config --global user.email)" = "$expect_email" ] || fail "global git email is '$(git config --global user.email)'"
ok "global git email"
tmp="$HOME/projects/argo/.dotfiles-test-$$"
mkdir -p "$tmp" && git -C "$tmp" init -q
argo_email="$(git -C "$tmp" config user.email)"
rm -rf "$tmp"
[ "$argo_email" = "CHANGE_ME@work.example" ] || fail "argo includeIf not applied, got '$argo_email'"
ok "argo includeIf"

# 5. Startup time (informational). python3 exists on macOS (CLT) and Debian.
now_ms() { python3 -c 'import time; print(int(time.time() * 1000))'; }
start="$(now_ms)"
zsh -ilc exit 2>/dev/null
end="$(now_ms)"
echo "startup: $(( end - start )) ms"
