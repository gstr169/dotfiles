# Dotfiles Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `~/.dotfiles` reproduce the working environment on a fresh macOS or Debian/Ubuntu machine with one command, replacing antigen with antidote, adding Brewfiles and a bootstrap script, and verifying the install in CI.

**Architecture:** Dotbot (pinned submodule) links files from the repo into `$HOME`; a bash `install` script wraps dotbot and adds package installation with remembered per-group prompts; `bootstrap.sh` prepares a blank machine and calls `install`. Zsh config is split into `zsh/zshenv`, `zsh/zprofile`, `zsh/zshrc` and ordered `zsh/rc.d/*.zsh` fragments; plugins are declared in `zsh/plugins.txt` and loaded by antidote (pinned submodule) through the `getantidote/use-omz` bridge.

**Tech Stack:** zsh 5.9, bash, dotbot v1.24.1, antidote v2.3.0, Homebrew (macOS and Linuxbrew), apt (Debian/Ubuntu), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-02-dotfiles-modernization-design.md`

## Global Constraints

- Target platforms: macOS (Apple Silicon and Intel) and Debian/Ubuntu Linux only. `bootstrap.sh` and `install` abort with a message on anything else.
- Submodules are pinned: dotbot at tag `v1.24.1`, antidote at tag `v2.3.0`. Never use `git submodule update --remote`.
- No hardcoded `/Users/dmitry_finko` paths anywhere. Use `$HOME`, `$HOMEBREW_PREFIX`, `$DOTFILES`.
- Every tool integration in zsh is guarded so a missing binary prints nothing: `(( $+commands[tool] ))`.
- The Python flow is unchanged: pyenv for interpreters, `virtualenv ~/.virtualenvs/<name> -p X.Y`, `uv pip compile` / `uv pip sync`.
- `EDITOR`/`VISUAL` = `micro` if present, else `nano`.
- Cask tokens: `docker-desktop` (not `docker`), `tailscale-app` (not `tailscale`).
- `pay-respects` is not in Homebrew; it is installed via `cargo install --locked pay-respects`, skipped by `--no-cargo`.
- Nothing from `~/.ssh` is tracked. Secrets are never committed.
- Deviation from spec, agreed here: there is no `install.linux.yaml` until a Linux-only link exists. Linux-specific behaviour lives in `install` and `linux-gui/`.
- Commit messages end with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Work on a branch `modernize` off `master`; do not push until Task 12 says so.

## File map

| Path | Responsibility |
|---|---|
| `bootstrap.sh` | Blank-machine entry point: OS check, CLT/apt prerequisites, Homebrew, clone, run `install` |
| `install` | Dotbot runner plus package install, prompts, chsh, follow-ups |
| `install.conf.yaml` | Dotbot: clean, create, link (both OSes) |
| `install.macos.yaml` | Dotbot: iTerm2 prefs folder |
| `Brewfile` | CLI formulae, both OSes |
| `Brewfile.macos` | Required casks and font |
| `Brewfile.macos.optional` | Optional casks in `# group:` sections |
| `apt-packages.txt` | Linux prerequisites |
| `linux-gui/*.sh` | One idempotent script per optional Linux GUI group |
| `scripts/cask-skip.sh` | Emits casks whose app already exists in `/Applications` |
| `macos-defaults.sh` | Optional macOS defaults |
| `zsh/zshenv`, `zsh/zprofile`, `zsh/zshrc` | Shell entry points |
| `zsh/rc.d/*.zsh` | Ordered interactive-shell fragments |
| `zsh/plugins.txt` | antidote bundle list |
| `zsh/p10k.zsh` | Prompt config (moved from `shell/.p10k.zsh`) |
| `git/gitconfig`, `git/gitconfig-argo`, `git/gitignore_global` | Git config |
| `config/micro/settings.json`, `config/lazygit/config.yml` | Editor and lazygit config |
| `iterm2/com.googlecode.iterm2.plist` | Live iTerm2 preferences |
| `tests/check-shell.sh` | Post-install assertions used locally and in CI |
| `.github/workflows/ci.yml` | Install on macos-latest and ubuntu-latest |
| `README.md`, `docs/TRY.md` | Docs |

---

### Task 1: Branch, submodules, and repo cleanup

**Files:**
- Modify: `.gitmodules`
- Delete: `antigen/`, `dotbot-pip/`, `install_pip.conf.yaml`, `requirements.txt`, `shell/zsh_custom_plugins/`, `iterm_conf/`, `config/antigenrc`
- Move: `shell/.p10k.zsh` to `zsh/p10k.zsh`, `config/zshrc` to `zsh/zshrc.old` (reference only, deleted in Task 3)
- Create: `.gitignore`

**Interfaces:**
- Produces: `antidote/antidote.zsh` at repo root (used by Task 3), `dotbot/bin/dotbot` (used by Task 8), `zsh/p10k.zsh`.

- [ ] **Step 1: Create the branch**

```bash
cd ~/.dotfiles && git checkout -b modernize
```

- [ ] **Step 2: Remove the antigen and dotbot-pip submodules**

```bash
cd ~/.dotfiles
git submodule deinit -f antigen dotbot-pip
git rm -f antigen dotbot-pip
rm -rf .git/modules/antigen .git/modules/dotbot-pip
```

- [ ] **Step 3: Pin dotbot to v1.24.1 and add antidote at v2.3.0**

```bash
cd ~/.dotfiles
git -C dotbot fetch --tags --quiet
git -C dotbot checkout --quiet v1.24.1
git -C dotbot submodule update --init --quiet
git submodule add https://github.com/mattmc3/antidote.git antidote
git -C antidote checkout --quiet v2.3.0
```

- [ ] **Step 4: Verify submodule state**

Run: `git submodule status`
Expected: exactly two lines, `antidote (v2.3.0)` and `dotbot (v1.24.1)`, neither prefixed with `-` or `+`.

- [ ] **Step 5: Remove obsolete files and move p10k**

```bash
cd ~/.dotfiles
git rm -f install_pip.conf.yaml requirements.txt config/antigenrc "iterm_conf/iTerm2 State.itermexport"
git rm -rf shell/zsh_custom_plugins 2>/dev/null || rm -rf shell/zsh_custom_plugins
mkdir -p zsh
git mv shell/.p10k.zsh zsh/p10k.zsh
git mv config/zshrc zsh/zshrc.old
rmdir shell config 2>/dev/null || true
```

- [ ] **Step 6: Write .gitignore**

```gitignore
.DS_Store
*.zwc
__pycache__/
Brewfile.lock.json
```

- [ ] **Step 7: Verify tree**

Run: `git status --short && ls`
Expected: `ls` shows `README.md antidote docs dotbot install install.conf.yaml zsh`; no `antigen`, `config`, `shell`, `iterm_conf`, `dotbot-pip`.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "Replace antigen with antidote, pin dotbot, remove pip installer

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Shell test harness

**Files:**
- Create: `tests/check-shell.sh`

**Interfaces:**
- Produces: `tests/check-shell.sh` (bash, exit 0 on success). Reads env `DOTFILES_EXPECT_EMAIL` (default `dmit.finn@yandex.ru`). Used by Task 3 (local), Task 10 (CI), Task 12 (migration).

- [ ] **Step 1: Write the test script**

```bash
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
```

- [ ] **Step 2: Make it executable and run it against the current (old) setup**

Run: `chmod +x tests/check-shell.sh && tests/check-shell.sh; echo "exit=$?"`
Expected: `FAIL missing on PATH inside zsh: fzf eza bat ...` and `exit=1`. This confirms the harness detects the unconfigured state. (If it fails earlier on stderr, that is also acceptable at this point; note what it printed.)

- [ ] **Step 3: Commit**

```bash
git add tests/check-shell.sh
git commit -m "Add post-install shell check script

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Zsh configuration

**Files:**
- Create: `zsh/zshenv`, `zsh/zprofile`, `zsh/zshrc`, `zsh/plugins.txt`, `zsh/rc.d/00-options.zsh`, `zsh/rc.d/10-path.zsh`, `zsh/rc.d/20-tools.zsh`, `zsh/rc.d/30-aliases.zsh`, `zsh/rc.d/40-python.zsh`, `zsh/rc.d/macos.zsh`, `zsh/rc.d/linux.zsh`
- Delete: `zsh/zshrc.old`

**Interfaces:**
- Consumes: `antidote/antidote.zsh`, `zsh/p10k.zsh` from Task 1.
- Produces: `$DOTFILES` env var (repo root, derived from the zshrc's real path), functions `mkvenv`, `uvsync`, `uvcompile`, `is-macos`, `is-linux`. Task 8 links these files to `~/.zshenv`, `~/.zprofile`, `~/.zshrc`.

- [ ] **Step 1: Write `zsh/zshenv`**

```zsh
# Sourced by EVERY zsh (scripts included). Keep it tiny: no PATH work, no output.
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export LANG="${LANG:-en_US.UTF-8}"

[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
```

- [ ] **Step 2: Write `zsh/zprofile`**

```zsh
# Login shells only: one-time PATH setup. iTerm2, Terminal, ssh and Linux
# terminals all start login shells, so this is where brew and pyenv go.

# Homebrew: first prefix that exists wins (Apple Silicon, Intel, Linuxbrew).
for _p in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
  if [[ -x "$_p/bin/brew" ]]; then
    eval "$("$_p/bin/brew" shellenv)"
    break
  fi
done
unset _p

# pyenv: shims must be on PATH before anything looks for python.
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
[[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)
(( $+commands[pyenv] )) && eval "$(pyenv init --path)"

# JetBrains Toolbox CLI launchers (pycharm, goland).
for _p in "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" \
          "$HOME/.local/share/JetBrains/Toolbox/scripts"; do
  [[ -d "$_p" ]] && path+=("$_p")
done
unset _p

# Editor: micro if installed, nano otherwise (nano ships everywhere).
if (( $+commands[micro] )); then
  export EDITOR=micro
else
  export EDITOR=nano
fi
export VISUAL="$EDITOR"
```

- [ ] **Step 3: Write `zsh/rc.d/00-options.zsh`**

```zsh
# Shell options and Oh My Zsh flags. Sourced BEFORE plugins load so OMZ honours them.

# History
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY       # timestamps in history
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicates
setopt HIST_IGNORE_SPACE      # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY          # share across tabs
setopt INC_APPEND_HISTORY

# Navigation
setopt AUTO_CD                # `dirname` == `cd dirname`
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS   # allow `# comment` on the command line

# Oh My Zsh flags (read by lib/ when it loads)
HIST_STAMPS="yyyy-mm-dd"
ENABLE_CORRECTION="true"
HYPHEN_INSENSITIVE="false"
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
zstyle ':omz:update' mode disabled

# Plugin settings
PER_DIRECTORY_HISTORY_TOGGLE='^G'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Helpers referenced by `conditional:` annotations in plugins.txt
is-macos() { [[ "$OSTYPE" == darwin* ]] }
is-linux() { [[ "$OSTYPE" == linux* ]] }
```

- [ ] **Step 4: Write `zsh/plugins.txt`**

```zsh
# antidote bundle list. Order matters: use-omz first, syntax/autosuggest last, theme after.
# Docs: https://antidote.sh  |  Enable an opt-in plugin by removing its leading '#'.

# --- Oh My Zsh bridge (must be first; handles compinit, compdef, $ZSH, caches) ---
getantidote/use-omz
ohmyzsh/ohmyzsh path:lib

# --- Oh My Zsh plugins ---
ohmyzsh/ohmyzsh path:plugins/git
ohmyzsh/ohmyzsh path:plugins/docker
ohmyzsh/ohmyzsh path:plugins/docker-compose
ohmyzsh/ohmyzsh path:plugins/extract
ohmyzsh/ohmyzsh path:plugins/pip
ohmyzsh/ohmyzsh path:plugins/python
ohmyzsh/ohmyzsh path:plugins/pyenv
ohmyzsh/ohmyzsh path:plugins/direnv
ohmyzsh/ohmyzsh path:plugins/kubectl
ohmyzsh/ohmyzsh path:plugins/helm
ohmyzsh/ohmyzsh path:plugins/terraform
ohmyzsh/ohmyzsh path:plugins/gh
ohmyzsh/ohmyzsh path:plugins/sudo
ohmyzsh/ohmyzsh path:plugins/copyfile
ohmyzsh/ohmyzsh path:plugins/copypath
ohmyzsh/ohmyzsh path:plugins/colored-man-pages
ohmyzsh/ohmyzsh path:plugins/brew conditional:is-macos
ohmyzsh/ohmyzsh path:plugins/macos conditional:is-macos

# --- Completions (fpath only) ---
zsh-users/zsh-completions path:src kind:fpath

# --- Behaviour ---
Aloxaf/fzf-tab
djui/alias-tips
CyberShadow/per-directory-history
MichaelAquilina/zsh-autoswitch-virtualenv

# --- Must load last, before the theme ---
z-shell/F-Sy-H kind:defer
zsh-users/zsh-autosuggestions kind:defer

# --- Theme ---
romkatv/powerlevel10k

# --- Opt-in (see docs/TRY.md) ---
#olets/zsh-abbr kind:defer
#MichaelAquilina/zsh-you-should-use
#wfxr/forgit
#ohmyzsh/ohmyzsh path:plugins/atuin      # needs: brew install atuin
```

- [ ] **Step 5: Write `zsh/zshrc`**

```zsh
# Interactive shells. Order: instant prompt -> options -> plugins -> rc.d -> theme -> local.

# Powerlevel10k instant prompt. Must stay at the top; nothing above may print.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Repo root, derived from this file's real path (works wherever the repo lives).
export DOTFILES="${${(%):-%x}:A:h:h}"

source "$DOTFILES/zsh/rc.d/00-options.zsh"

# Plugins via antidote (static file rebuilt only when plugins.txt changes).
source "$DOTFILES/antidote/antidote.zsh"
antidote load "$DOTFILES/zsh/plugins.txt" "${XDG_CACHE_HOME:-$HOME/.cache}/antidote/plugins.zsh"

for _f in "$DOTFILES"/zsh/rc.d/[1-9]*.zsh; do
  source "$_f"
done
unset _f

case "$OSTYPE" in
  darwin*) source "$DOTFILES/zsh/rc.d/macos.zsh" ;;
  linux*)  source "$DOTFILES/zsh/rc.d/linux.zsh" ;;
esac

[[ -f "$DOTFILES/zsh/p10k.zsh" ]] && source "$DOTFILES/zsh/p10k.zsh"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
```

- [ ] **Step 6: Write `zsh/rc.d/10-path.zsh`**

```zsh
# PATH assembly. brew shellenv (zprofile) already set HOMEBREW_PREFIX and brew paths.
typeset -U path fpath   # keep entries unique

path=("$HOME/.local/bin" "$HOME/bin" $path)

if [[ -n "$HOMEBREW_PREFIX" ]]; then
  [[ -d "$HOMEBREW_PREFIX/opt/libpq/bin" ]] && path=("$HOMEBREW_PREFIX/opt/libpq/bin" $path)

  # Build flags so psycopg2 and friends find brew's openssl/zlib.
  if [[ -d "$HOMEBREW_PREFIX/opt/openssl@3" && -d "$HOMEBREW_PREFIX/opt/zlib" ]]; then
    export LDFLAGS="-L$HOMEBREW_PREFIX/opt/openssl@3/lib -L$HOMEBREW_PREFIX/opt/zlib/lib"
    export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/openssl@3/include -I$HOMEBREW_PREFIX/opt/zlib/include"
  fi
fi

export GOPATH="${GOPATH:-$HOME/go}"
[[ -d "$GOPATH/bin" ]] && path+=("$GOPATH/bin")
[[ -d "$HOME/.cargo/bin" ]] && path+=("$HOME/.cargo/bin")

# Non-login interactive shells (e.g. `zsh` typed in a terminal) skip zprofile.
if [[ -z "$EDITOR" ]]; then
  (( $+commands[micro] )) && export EDITOR=micro || export EDITOR=nano
  export VISUAL="$EDITOR"
fi
```

- [ ] **Step 7: Write `zsh/rc.d/20-tools.zsh`**

```zsh
# Tool integrations. Every block is guarded: a missing binary prints nothing.
# pyenv and direnv hooks come from their Oh My Zsh plugins (plugins.txt).

# fzf: Ctrl+R history, Ctrl+T files, Alt+C directories.
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  (( $+commands[bat] )) && export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
fi

# fzf-tab: previews for cd and directory completion.
if (( $+commands[eza] )); then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
fi
zstyle ':completion:*' menu no

# zoxide: `z dir` jumps to the best match, `zi` picks interactively.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd z)"

# bat as pager for man pages when available.
if (( $+commands[bat] )); then
  export BAT_THEME="${BAT_THEME:-Monokai Extended}"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# pay-respects: type `f` after a failed command to get the fixed one.
(( $+commands[pay-respects] )) && eval "$(pay-respects zsh --alias f)"

# Google Cloud SDK, manual install location.
if [[ -d "$HOME/google-cloud-sdk" ]]; then
  [[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
  [[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi
```

- [ ] **Step 8: Write `zsh/rc.d/30-aliases.zsh`**

```zsh
# Aliases. grep and find are deliberately NOT aliased (rg/fd have different flags).

if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons'
  alias ll='eza -l --group-directories-first --icons --git'
  alias la='eza -la --group-directories-first --icons --git'
  alias lt='eza --tree --level=2 --icons'
else
  alias ll='ls -lh'
  alias la='ls -lAh'
fi

if (( $+commands[bat] )); then
  alias cat='bat --paging=never --style=plain'
fi

(( $+commands[lazygit] )) && alias lg='lazygit'
(( $+commands[terraform] )) && alias tf='terraform'
alias x='extract'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias dotfiles='cd "$DOTFILES"'
alias reload='exec zsh'
```

- [ ] **Step 9: Write `zsh/rc.d/40-python.zsh`**

```zsh
# Python workflow: pyenv (interpreters) + virtualenv in ~/.virtualenvs + uv (compile/sync).
# The underlying commands are unchanged; these are shortcuts.

export VIRTUALENV_HOME="${VIRTUALENV_HOME:-$HOME/.virtualenvs}"
export AUTOSWITCH_VIRTUAL_ENV_DIR="$VIRTUALENV_HOME"
export AUTOSWITCH_SILENT=1

# mkvenv <name> <python-version>
#   virtualenv ~/.virtualenvs/<name> -p <version>, then write .venv so autoswitch activates it.
mkvenv() {
  if [[ $# -ne 2 ]]; then
    print -u2 "usage: mkvenv <name> <python-version>   e.g. mkvenv argo-backend-3.11 3.11"
    return 2
  fi
  local name="$1" pyver="$2"
  virtualenv "$VIRTUALENV_HOME/$name" -p "$pyver" || return
  print -r -- "$name" > .venv
  print "created $VIRTUALENV_HOME/$name and wrote .venv"
}

# uvcompile: requirements/requirements.in -> requirements/requirements.txt (or top-level).
uvcompile() {
  if [[ -f requirements/requirements.in ]]; then
    uv pip compile requirements/requirements.in -o requirements/requirements.txt "$@"
  elif [[ -f requirements.in ]]; then
    uv pip compile requirements.in -o requirements.txt "$@"
  else
    print -u2 "uvcompile: no requirements.in found"; return 1
  fi
}

# uvsync: install exactly what the compiled files say.
uvsync() {
  local -a files
  [[ -f requirements/requirements.txt ]] && files+=(requirements/requirements.txt)
  [[ -f requirements/dev-requirements.txt ]] && files+=(requirements/dev-requirements.txt)
  (( $#files )) || { [[ -f requirements.txt ]] && files=(requirements.txt) }
  (( $#files )) || { print -u2 "uvsync: no requirements files found"; return 1 }
  uv pip sync "${files[@]}" "$@"
}
```

- [ ] **Step 10: Write `zsh/rc.d/macos.zsh` and `zsh/rc.d/linux.zsh`**

`zsh/rc.d/macos.zsh`:
```zsh
# macOS only.
export HOMEBREW_NO_ENV_HINTS=1
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
```

`zsh/rc.d/linux.zsh`:
```zsh
# Linux only.
(( $+commands[xdg-open] )) && alias open='xdg-open'
if (( $+commands[xclip] )); then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi
```

- [ ] **Step 11: Delete the old zshrc**

```bash
git rm -f zsh/zshrc.old
```

- [ ] **Step 12: Smoke-test the new config in a scratch HOME (does not touch the real home)**

```bash
S=/private/tmp/claude-501/-Users-dmitry-finko--dotfiles/cf19ab2c-fc4d-47d7-ad27-3c6055427328/scratchpad/home-test
rm -rf "$S" && mkdir -p "$S"
ln -s ~/.dotfiles/zsh/zshenv "$S/.zshenv"
ln -s ~/.dotfiles/zsh/zprofile "$S/.zprofile"
ln -s ~/.dotfiles/zsh/zshrc "$S/.zshrc"
HOME="$S" script -q /dev/null bash -c 'zsh -ilc "echo DOTFILES=\$DOTFILES; echo EDITOR=\$EDITOR; type mkvenv | head -1; alias ll" 2>"$HOME/err.log"' | tail -5
echo "--- stderr ---"; cat "$S/err.log"
```
Expected: first run clones plugins (network) and prints `DOTFILES=/Users/dmitry_finko/.dotfiles`, `EDITOR=nano` (micro is not installed yet), `mkvenv is a shell function`, and the `ll` alias. `err.log` must be empty. If it contains `compdef: command not found`, add `autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"` directly after `source "$DOTFILES/zsh/rc.d/00-options.zsh"` in `zsh/zshrc` and re-run. If it contains p10k instant-prompt warnings about console output, confirm nothing in `rc.d` prints and re-run.

- [ ] **Step 13: Run it a second time and time it**

Run: `HOME="$S" bash -c 'time zsh -ilc exit' 2>&1 | grep real`
Expected: under 0.5 s on the second run (plugins cached).

- [ ] **Step 14: Commit**

```bash
git add zsh
git commit -m "Split zsh config into zshenv/zprofile/zshrc and rc.d fragments; load plugins with antidote

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Git configuration

**Files:**
- Create: `git/gitconfig`, `git/gitconfig-argo`, `git/gitignore_global`

**Interfaces:**
- Produces: files linked by Task 8 to `~/.gitconfig` and `~/.config/git/ignore`. `git/gitconfig-argo` contains the literal placeholder `CHANGE_ME@work.example` asserted by `tests/check-shell.sh`.

- [ ] **Step 1: Write `git/gitconfig`**

```gitconfig
[user]
	name = dmitry.finko
	email = dmit.finn@yandex.ru

[init]
	defaultBranch = main
[pull]
	rebase = true
[push]
	autoSetupRemote = true
	default = current
[fetch]
	prune = true
[rerere]
	enabled = true
[diff]
	colorMoved = default
[merge]
	conflictStyle = zdiff3

[core]
	excludesfile = ~/.config/git/ignore
	pager = delta
[interactive]
	diffFilter = delta --color-only
[delta]
	navigate = true
	side-by-side = true
	line-numbers = true

# Work identity for everything under ~/projects/argo/
[includeIf "gitdir:~/projects/argo/"]
	path = ~/.dotfiles/git/gitconfig-argo

# Machine-local overrides (signing key, credential helper, ...). Ignored if missing.
[include]
	path = ~/.gitconfig.local
```

- [ ] **Step 2: Write `git/gitconfig-argo`**

```gitconfig
# Applied automatically for repos under ~/projects/argo/ (see gitconfig includeIf).
# Replace the placeholder email after install.
[user]
	email = CHANGE_ME@work.example
[core]
	sshCommand = ssh -i ~/.ssh/argo_id_rsa
```

- [ ] **Step 3: Write `git/gitignore_global`**

```gitignore
.DS_Store
.idea/
.vscode/
.venv/
venv/
__pycache__/
*.pyc
.env.local
**/.claude/settings.local.json
```

- [ ] **Step 4: Verify the config parses and delta is optional**

```bash
git config --file git/gitconfig --list | head -3
git config --file git/gitconfig --get 'includeIf.gitdir:~/projects/argo/.path'
```
Expected: first command prints `user.name=dmitry.finko` first; second prints `~/.dotfiles/git/gitconfig-argo`. Note: `core.pager = delta` makes `git log` fail with "delta: command not found" if delta is missing. Delta is in the Brewfile (Task 6); `tests/check-shell.sh` asserts the Brewfile ran before git is used.

- [ ] **Step 5: Commit**

```bash
git add git
git commit -m "Track git config with delta, includeIf work identity, global ignore

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Editor, lazygit, iTerm2 and macOS defaults

**Files:**
- Create: `config/micro/settings.json`, `config/lazygit/config.yml`, `iterm2/com.googlecode.iterm2.plist`, `macos-defaults.sh`, `install.macos.yaml`

**Interfaces:**
- Produces: files linked by Task 8; `install.macos.yaml` run by `install` on Darwin; `macos-defaults.sh` run by `install` when the `macos-defaults` prompt is accepted.

- [ ] **Step 1: Write `config/micro/settings.json`**

```json
{
    "colorscheme": "monokai",
    "mouse": true,
    "rmtrailingws": true,
    "softwrap": true,
    "tabsize": 4,
    "tabstospaces": true,
    "scrollbar": true,
    "savecursor": true
}
```

- [ ] **Step 2: Write `config/lazygit/config.yml`**

```yaml
gui:
  nerdFontsVersion: "3"
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
```

- [ ] **Step 3: Export the live iTerm2 preferences**

```bash
mkdir -p iterm2
defaults export com.googlecode.iterm2 iterm2/com.googlecode.iterm2.plist
plutil -lint iterm2/com.googlecode.iterm2.plist
grep -c 'MesloLGS' iterm2/com.googlecode.iterm2.plist
```
Expected: `plutil` prints `OK`; grep count is at least 1 (the Nerd Font is configured). If the count is 0, tell the user the export does not reference MesloLGS and continue.

- [ ] **Step 4: Write `install.macos.yaml`**

```yaml
# macOS-only dotbot steps. Run by ./install after install.conf.yaml.
- shell:
  - description: Point iTerm2 at the tracked preferences folder
    command: |
      defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.dotfiles/iterm2"
      defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
    stderr: true
```

- [ ] **Step 5: Write `macos-defaults.sh`**

```bash
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
```

- [ ] **Step 6: Verify**

```bash
chmod +x macos-defaults.sh
python3 -c "import json;json.load(open('config/micro/settings.json'))" && echo json-ok
bash -n macos-defaults.sh && echo bash-ok
```
Expected: `json-ok`, `bash-ok`.

- [ ] **Step 7: Commit**

```bash
git add config iterm2 macos-defaults.sh install.macos.yaml
git commit -m "Add micro, lazygit, iTerm2 preferences and optional macOS defaults

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Package manifests

**Files:**
- Create: `Brewfile`, `Brewfile.macos`, `Brewfile.macos.optional`, `apt-packages.txt`, `scripts/cask-skip.sh`

**Interfaces:**
- Produces: `Brewfile.macos.optional` group format `# group: <key> | <Description: apps>` followed by `cask` lines, parsed by `install` (Task 8). `scripts/cask-skip.sh <Brewfile...>` prints space-separated cask tokens to skip.

- [ ] **Step 1: Write `Brewfile`**

```ruby
# CLI tools for both macOS and Linux (Homebrew / Linuxbrew).
# Install: brew bundle --file=Brewfile

# --- shell and cli ---
brew "zsh"
brew "git"
brew "git-lfs"
brew "git-flow-avh"
brew "micro"
brew "fzf"
brew "zoxide"
brew "eza"
brew "bat"
brew "ripgrep"
brew "fd"
brew "git-delta"
brew "lazygit"
brew "jq"
brew "tree"
brew "wget"
brew "sevenzip"
brew "age"
brew "sops"
brew "rclone"
brew "magic-wormhole"
brew "yt-dlp"
brew "ffmpeg"
brew "nmap"
brew "sshpass"

# --- python ---
brew "pyenv"
brew "virtualenv"
brew "uv"
brew "black"
brew "python@3.13"

# --- go and rust ---
brew "go"
brew "rustup"

# --- cloud and kubernetes ---
brew "awscli"
brew "awscurl"
brew "kubernetes-cli"
brew "helm"
brew "k9s"
brew "stern"
brew "gh"

# --- databases ---
brew "libpq"
brew "postgresql@14"
```

- [ ] **Step 2: Write `Brewfile.macos`**

```ruby
# Required macOS GUI apps and the prompt font.
cask "font-meslo-lg-nerd-font"
cask "iterm2"
cask "sublime-text"
cask "jetbrains-toolbox"
cask "docker-desktop"
cask "google-chrome"
cask "enpass"
```

- [ ] **Step 3: Write `Brewfile.macos.optional`**

```ruby
# Optional macOS apps. ./install asks once per group and remembers the answer
# in ~/.dotfiles.local. Group header format is parsed by install; keep it:
#   # group: <key> | <Description shown in the prompt>

# group: messaging | Messaging: Slack, Telegram
cask "slack"
cask "telegram"

# group: notes-ai | Notes and AI: Notion, Claude, ChatGPT
cask "notion"
cask "claude"
cask "chatgpt"

# group: media-cloud | Media and cloud: VLC, Google Drive
cask "vlc"
cask "google-drive"

# group: network | Network: Tailscale
cask "tailscale-app"
```

- [ ] **Step 4: Write `apt-packages.txt`**

```text
build-essential
zsh
git
curl
file
procps
ca-certificates
gnupg
nano
```

- [ ] **Step 5: Write `scripts/cask-skip.sh`**

```bash
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
```

- [ ] **Step 6: Verify on this machine**

```bash
chmod +x scripts/cask-skip.sh
brew bundle check --file=Brewfile 2>&1 | tail -3
scripts/cask-skip.sh Brewfile.macos Brewfile.macos.optional
```
Expected: `brew bundle check` lists missing formulae (fzf, eza, ... are not installed yet) and exits non-zero, which is fine. `cask-skip.sh` prints tokens for apps present in `/Applications` but not brew-managed, for example `google-chrome slack telegram notion claude chatgpt vlc google-drive tailscale-app enpass` (exact list depends on the machine); it must not error.

- [ ] **Step 7: Commit**

```bash
git add Brewfile Brewfile.macos Brewfile.macos.optional apt-packages.txt scripts/cask-skip.sh
git commit -m "Add Brewfiles, apt prerequisites, and hand-installed cask detection

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Linux optional GUI groups

**Files:**
- Create: `linux-gui/browser-editors.sh`, `linux-gui/messaging.sh`, `linux-gui/media.sh`, `linux-gui/network.sh`, `linux-gui/docker.sh`

**Interfaces:**
- Produces: one executable per group. Line 2 of each file is `# desc: <Description shown in the prompt>`; `install` (Task 8) reads it with `sed -n '2s/^# desc: //p'`. Each script is idempotent and uses `sudo` internally.

- [ ] **Step 1: Write `linux-gui/browser-editors.sh`**

```bash
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
```

- [ ] **Step 2: Write `linux-gui/messaging.sh`**

```bash
#!/usr/bin/env bash
# desc: Messaging: Slack, Telegram (via Flatpak)
set -euo pipefail
if ! command -v flatpak >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y flatpak
fi
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive flathub com.slack.Slack org.telegram.desktop
```

- [ ] **Step 3: Write `linux-gui/media.sh`**

```bash
#!/usr/bin/env bash
# desc: Media: VLC
set -euo pipefail
sudo apt-get update -qq
sudo apt-get install -y vlc
```

- [ ] **Step 4: Write `linux-gui/network.sh`**

```bash
#!/usr/bin/env bash
# desc: Network: Tailscale
set -euo pipefail
if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
echo "Run 'sudo tailscale up' to sign in."
```

- [ ] **Step 5: Write `linux-gui/docker.sh`**

```bash
#!/usr/bin/env bash
# desc: Docker Engine and compose plugin (adds you to the docker group)
set -euo pipefail
if ! command -v docker >/dev/null; then
  . /etc/os-release
  sudo install -d -m 0755 /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/$ID/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  echo "Added $USER to the docker group. Log out and back in for it to take effect."
fi
```

- [ ] **Step 6: Verify syntax and headers**

```bash
chmod +x linux-gui/*.sh
for f in linux-gui/*.sh; do bash -n "$f" && printf '%s: %s\n' "$f" "$(sed -n '2s/^# desc: //p' "$f")"; done
```
Expected: five lines, each with a non-empty description.

- [ ] **Step 7: Commit**

```bash
git add linux-gui
git commit -m "Add optional Linux GUI install groups

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Dotbot config and the install script

**Files:**
- Modify: `install.conf.yaml` (rewrite), `install` (rewrite)

**Interfaces:**
- Consumes: `dotbot/bin/dotbot`, `Brewfile*`, `apt-packages.txt`, `linux-gui/*.sh` (`# desc:` on line 2), `scripts/cask-skip.sh`, `install.macos.yaml`, `macos-defaults.sh`, `tests/check-shell.sh`.
- Produces: `./install [--all|--none] [--no-gui] [--no-chsh] [--no-cargo]`; state file `~/.dotfiles.local` with lines `group_<key>=y|n`. `bootstrap.sh` (Task 9) execs this.

- [ ] **Step 1: Rewrite `install.conf.yaml`**

```yaml
# Dotbot config shared by macOS and Linux. Run via ./install, not directly.
- defaults:
    link:
      create: true
      relink: true
      force: true
    clean:
      force: true

# Remove dead symlinks (including the old ~/.antigen.zsh, ~/.antigenrc, ~/.shell).
- clean: ['~', '~/.config/git', '~/.config/micro', '~/.config/lazygit']

- create:
    ~/projects:
    ~/.virtualenvs:
    ~/.config/git:
    ~/.config/micro:
    ~/.config/lazygit:
    ~/.ssh:
      mode: 0700

- link:
    ~/.zshenv: zsh/zshenv
    ~/.zprofile: zsh/zprofile
    ~/.zshrc: zsh/zshrc
    ~/.gitconfig: git/gitconfig
    ~/.config/git/ignore: git/gitignore_global
    ~/.config/micro/settings.json: config/micro/settings.json
    ~/.config/lazygit/config.yml: config/lazygit/config.yml
```

- [ ] **Step 2: Rewrite `install`**

```bash
#!/usr/bin/env bash
# Dotfiles installer. Safe to re-run. See README.md.
#   ./install [--all|--none] [--no-gui] [--no-chsh] [--no-cargo]
set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASEDIR"

usage() {
  sed -n '2,4p' "$0"
  cat <<'EOF'
  --all       accept every optional group without asking
  --none      decline every optional group without asking
  --no-gui    skip GUI apps (casks / linux-gui) entirely
  --no-chsh   do not change the login shell
  --no-cargo  skip cargo-installed tools (pay-respects)
Answers to prompts are remembered in ~/.dotfiles.local; delete a line there to be asked again.
EOF
}

ANSWER_ALL=""; NO_GUI=""; NO_CHSH=""; NO_CARGO=""
for arg in "$@"; do
  case "$arg" in
    --all) ANSWER_ALL=y ;;
    --none) ANSWER_ALL=n ;;
    --no-gui) NO_GUI=1 ;;
    --no-chsh) NO_CHSH=1 ;;
    --no-cargo) NO_CARGO=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install: unknown flag '$arg'" >&2; usage >&2; exit 2 ;;
  esac
done

OS="$(uname -s)"
case "$OS" in
  Darwin) ;;
  Linux) [ -f /etc/debian_version ] || { echo "install: only Debian/Ubuntu Linux is supported" >&2; exit 1; } ;;
  *) echo "install: unsupported OS '$OS'" >&2; exit 1 ;;
esac

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*"; }

# --- remembered answers ---------------------------------------------------
STATE="$HOME/.dotfiles.local"
touch "$STATE"
state_get() { grep -E "^$1=" "$STATE" | tail -1 | cut -d= -f2- || true; }
state_set() {
  { grep -vE "^$1=" "$STATE" || true; echo "$1=$2"; } > "$STATE.tmp"
  mv "$STATE.tmp" "$STATE"
}
# ask_group KEY DESCRIPTION -> exit 0 if accepted
ask_group() {
  local key="$1" desc="$2" ans
  ans="$(state_get "group_$key")"
  if [ -z "$ans" ]; then
    if [ -n "$ANSWER_ALL" ]; then
      ans="$ANSWER_ALL"
    else
      read -r -p "Install $desc? [y/N] " ans </dev/tty || ans=n
      ans="${ans:-n}"
    fi
    state_set "group_$key" "$ans"
  fi
  [[ "$ans" =~ ^[Yy] ]]
}

# --- homebrew on PATH for this run ----------------------------------------
for p in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
  if [ -x "$p/bin/brew" ]; then eval "$("$p/bin/brew" shellenv)"; break; fi
done
command -v brew >/dev/null || { echo "install: Homebrew not found; run ./bootstrap.sh first" >&2; exit 1; }
export HOMEBREW_NO_ENV_HINTS=1

# --- 1. submodules and dotbot ---------------------------------------------
log "Submodules"
git submodule update --init --recursive

log "Backing up files that will be replaced by symlinks"
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
while read -r target; do
  target="${target/#\~/$HOME}"
  if [ -f "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$backup_dir"
    cp -p "$target" "$backup_dir/$(basename "$target")"
    echo "  $target -> $backup_dir/"
  fi
done < <(sed -nE 's/^    (~[^:]+):.*/\1/p' install.conf.yaml)
[ -d "$backup_dir" ] || echo "  nothing to back up"

log "Dotbot: links and directories"
./dotbot/bin/dotbot -d "$BASEDIR" -c install.conf.yaml
[ "$OS" = Darwin ] && ./dotbot/bin/dotbot -d "$BASEDIR" -c install.macos.yaml

# --- 2. packages ------------------------------------------------------------
log "Homebrew CLI packages"
brew bundle --file=Brewfile

if [ "$OS" = Darwin ] && [ -z "$NO_GUI" ]; then
  log "macOS apps"
  HOMEBREW_BUNDLE_CASK_SKIP="$(scripts/cask-skip.sh Brewfile.macos Brewfile.macos.optional)"
  export HOMEBREW_BUNDLE_CASK_SKIP
  [ -n "$HOMEBREW_BUNDLE_CASK_SKIP" ] && echo "  already in /Applications, skipping: $HOMEBREW_BUNDLE_CASK_SKIP"
  brew bundle --file=Brewfile.macos

  optional_tmp="$(mktemp)"
  while read -r key desc; do
    if ask_group "$key" "$desc"; then
      awk -v g="$key" '/^# group: /{on=($0 ~ "^# group: "g" ")} on && /^cask /' Brewfile.macos.optional >> "$optional_tmp"
    fi
  done < <(sed -nE 's/^# group: ([^ ]+) \| (.*)$/\1 \2/p' Brewfile.macos.optional)
  if [ -s "$optional_tmp" ]; then brew bundle --file="$optional_tmp"; fi
  rm -f "$optional_tmp"

  if ask_group macos-defaults "macOS defaults (fast key repeat, show hidden files)"; then
    ./macos-defaults.sh
  fi
fi

if [ "$OS" = Linux ] && [ -z "$NO_GUI" ]; then
  log "Linux GUI apps"
  for script in linux-gui/*.sh; do
    key="$(basename "$script" .sh)"
    desc="$(sed -n '2s/^# desc: //p' "$script")"
    if ask_group "$key" "$desc"; then "$script"; fi
  done
  echo "  Not available on Linux (use the web apps): Notion, Claude desktop, ChatGPT desktop, Google Drive (use rclone)."
fi

# --- 3. cargo tools ----------------------------------------------------------
if [ -z "$NO_CARGO" ]; then
  log "Cargo tools"
  if command -v rustup >/dev/null && ! rustup toolchain list 2>/dev/null | grep -q stable; then
    rustup default stable
  fi
  if command -v cargo >/dev/null; then
    command -v pay-respects >/dev/null || cargo install --locked pay-respects
  else
    warn "cargo not found; skipping pay-respects (run: rustup default stable && cargo install --locked pay-respects)"
  fi
fi

# --- 4. login shell ----------------------------------------------------------
if [ -z "$NO_CHSH" ]; then
  zsh_path="$(command -v zsh)"
  if [ "$(basename "${SHELL:-}")" != zsh ]; then
    log "Login shell -> $zsh_path"
    grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$zsh_path"
  fi
fi

# --- 5. follow-ups ------------------------------------------------------------
log "Done. Manual follow-ups:"
cat <<EOF
  - Open a new terminal (antidote clones plugins on first start; that one takes longer).
  - Copy ~/.ssh keys and ~/.ssh/config from the old machine (nothing SSH is tracked).
  - Set the work email in $BASEDIR/git/gitconfig-argo (placeholder CHANGE_ME@work.example).
  - pyenv install <versions you need>; pyenv global <version>.
  - Sign in to JetBrains Toolbox and install PyCharm / GoLand.
  - Google Cloud SDK, if needed: install to ~/google-cloud-sdk (auto-detected by the shell).
EOF
[ "$OS" = Linux ] && echo "  - Log out and back in if you were added to the docker group."
echo "  - Verify: $BASEDIR/tests/check-shell.sh"
```

- [ ] **Step 3: Syntax-check and read the help**

Run: `chmod +x install && bash -n install && ./install --help`
Expected: usage text with the five flags.

- [ ] **Step 4: Dry-run the dotbot part in a scratch HOME**

```bash
S=/private/tmp/claude-501/-Users-dmitry-finko--dotfiles/cf19ab2c-fc4d-47d7-ad27-3c6055427328/scratchpad/home-install
rm -rf "$S" && mkdir -p "$S"
HOME="$S" ./dotbot/bin/dotbot -d "$PWD" -c install.conf.yaml
ls -la "$S" "$S/.config/git" "$S/.config/micro" "$S/.config/lazygit"
stat -f '%Lp %N' "$S/.ssh"
```
Expected: dotbot prints `==> All tasks executed successfully`; `.zshenv`, `.zprofile`, `.zshrc`, `.gitconfig` are symlinks into the repo; `.ssh` mode is `700`.

- [ ] **Step 5: Dry-run the optional-group parser**

```bash
sed -nE 's/^# group: ([^ ]+) \| (.*)$/\1 \2/p' Brewfile.macos.optional
awk -v g="messaging" '/^# group: /{on=($0 ~ "^# group: "g" ")} on && /^cask /' Brewfile.macos.optional
```
Expected: four `key description` lines; then exactly `cask "slack"` and `cask "telegram"`.

- [ ] **Step 6: Commit**

```bash
git add install install.conf.yaml
git commit -m "Rewrite install: dotbot links, brew bundles, remembered optional groups, chsh

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Bootstrap script

**Files:**
- Create: `bootstrap.sh`

**Interfaces:**
- Consumes: `install` flags (passed through), `apt-packages.txt` (read from the cloned repo).
- Produces: `bootstrap.sh [install flags]`, runnable via `curl | bash` or from inside the repo. When run from a file inside `~/.dotfiles` it does not clone or pull.

- [ ] **Step 1: Write `bootstrap.sh`**

```bash
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
```

- [ ] **Step 2: Syntax-check and verify the inside-repo detection**

```bash
chmod +x bootstrap.sh && bash -n bootstrap.sh && echo syntax-ok
bash -c 'self=bootstrap.sh; DOTFILES=$HOME/.dotfiles; [ "$(cd "$(dirname "$self")" && pwd -P)" = "$(cd "$DOTFILES" && pwd -P)" ] && echo inside-repo'
```
Expected: `syntax-ok`, `inside-repo`.

- [ ] **Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "Add bootstrap script for blank machines

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: CI workflow

**Files:**
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: `bootstrap.sh --none --no-gui --no-chsh --no-cargo`, `tests/check-shell.sh`.

- [ ] **Step 1: Write `.github/workflows/ci.yml`**

```yaml
name: ci
on:
  push:
  pull_request:

jobs:
  install:
    strategy:
      fail-fast: false
      matrix:
        os: [macos-latest, ubuntu-latest]
    runs-on: ${{ matrix.os }}
    env:
      HOMEBREW_NO_AUTO_UPDATE: "1"
      HOMEBREW_NO_INSTALL_CLEANUP: "1"
      HOMEBREW_NO_ENV_HINTS: "1"
      # Heavy formulae that add nothing to the shell checks.
      HOMEBREW_BUNDLE_BREW_SKIP: "ffmpeg postgresql@14 awscli awscurl helm k9s stern kubernetes-cli nmap go rustup libpq python@3.13 magic-wormhole yt-dlp black sops age rclone sevenzip git-lfs git-flow-avh sshpass"
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Expose the checkout as ~/.dotfiles
        run: ln -sfn "$GITHUB_WORKSPACE" "$HOME/.dotfiles"

      - name: Bootstrap and install (non-interactive)
        run: ./bootstrap.sh --none --no-gui --no-chsh --no-cargo

      - name: Shell checks
        run: tests/check-shell.sh
```

- [ ] **Step 2: Validate YAML**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml')); print('yaml-ok')"` (if PyYAML is missing, use `./dotbot/lib/pyyaml` via `PYTHONPATH=dotbot/lib/pyyaml/lib python3 -c ...`).
Expected: `yaml-ok`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "Add CI: install on macOS and Ubuntu, run shell checks

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 11: README and try-list

**Files:**
- Modify: `README.md` (rewrite)
- Create: `docs/TRY.md`

- [ ] **Step 1: Rewrite `README.md`**

```markdown
# dotfiles

Shell and tool setup for macOS (Apple Silicon or Intel) and Debian/Ubuntu.
Managed by [dotbot](https://github.com/anishathalye/dotbot) (symlinks) and
[antidote](https://antidote.sh) (zsh plugins).

## New machine

```bash
curl -fsSL https://raw.githubusercontent.com/gstr169/dotfiles/master/bootstrap.sh | bash
```

That installs build tools, Homebrew, clones this repo to `~/.dotfiles`, links
the config files, installs packages, and asks once per optional app group.

On an already-configured machine, just run `./install` again. It is idempotent.

Flags (pass to `./install`, or after `bash -s --` when piping):

| Flag | Effect |
|---|---|
| `--all` / `--none` | accept or decline every optional group without asking |
| `--no-gui` | skip GUI apps entirely |
| `--no-chsh` | do not change the login shell |
| `--no-cargo` | skip cargo-installed tools |

Answers are remembered in `~/.dotfiles.local`. Delete a line to be asked again.

## What gets installed

| | macOS | Linux |
|---|---|---|
| CLI (`Brewfile`) | fzf, zoxide, eza, bat, ripgrep, fd, delta, lazygit, micro, jq, git-flow, awscli, kubectl, helm, k9s, stern, gh, pyenv, virtualenv, uv, black, go, rustup, libpq, postgresql@14, ... | same, via Linuxbrew |
| Required GUI (`Brewfile.macos`) | iTerm2, Sublime Text, JetBrains Toolbox, Docker Desktop, Chrome, Enpass, MesloLGS Nerd Font | none |
| Optional groups | Messaging, Notes and AI, Media and cloud, Network | Browser and editors, Messaging, Media, Network, Docker Engine (`linux-gui/`) |
| Prompt and editor | powerlevel10k; `EDITOR` = micro, nano fallback | same |

Not managed: SSH keys, Google Cloud SDK (install to `~/google-cloud-sdk`; it is
auto-detected), pyenv Python versions, JetBrains IDEs (use Toolbox).

## After install

- Copy `~/.ssh` from the old machine.
- Put the work email in `git/gitconfig-argo` (applies under `~/projects/argo/`).
- `pyenv install 3.12.x && pyenv global 3.12.x`.
- Open a new terminal. First start clones plugins and is slower.
- Run `tests/check-shell.sh` to verify.
- See [docs/TRY.md](docs/TRY.md) for the new tools worth learning.

## Layout

- `zsh/zshenv`, `zsh/zprofile`, `zsh/zshrc`: shell entry points, linked into `~`.
- `zsh/rc.d/`: numbered fragments sourced in order; `macos.zsh` / `linux.zsh` per OS.
- `zsh/plugins.txt`: antidote plugin list. Edit, then open a new shell.
- `git/`, `config/micro`, `config/lazygit`: linked into `~` and `~/.config`.
- `iterm2/`: iTerm2 reads and writes its preferences here. Changes show as diffs; commit them.
- `~/.zshrc.local`, `~/.zshenv.local`, `~/.gitconfig.local`: untracked per-machine overrides, sourced if present.

## Adding things

- A CLI tool: add `brew "name"` to `Brewfile`, run `brew bundle --file=Brewfile`.
- A zsh plugin: add a line to `zsh/plugins.txt` (`owner/repo`, optional `kind:defer`).
- A macOS app: `cask "token"` in `Brewfile.macos` or under a group in `Brewfile.macos.optional`.

## Python workflow (unchanged)

```bash
pyenv local 3.11.9                  # per project
mkvenv argo-backend-3.11 3.11       # virtualenv in ~/.virtualenvs + .venv marker
uvcompile                           # requirements/requirements.in -> .txt
uvsync                              # uv pip sync requirements/*.txt
```

## Cleanup after migrating from the old setup

```bash
rm -rf ~/.antigen ~/.antigen_plugin_lastupdate ~/.antigen_system_lastupdate ~/.antigenrc.zwc ~/.zshrc.zwc
rm -f ~/.zshrc.backup ~/.zprofile.bak ~/.zprofileeval
```

## History

Originally based on [mom1/dotfiles](https://github.com/mom1/dotfiles) with antigen.
Rewritten in September 2026 around dotbot, antidote and Homebrew bundles.
```

- [ ] **Step 2: Write `docs/TRY.md`**

```markdown
# Things to try

Ordered by expected payoff. Each entry: what it replaces, the two or three
commands worth learning first.

## Shell navigation

**fzf** (fuzzy finder). Replaces scrolling through history.
- `Ctrl+R`: fuzzy search history. Type a few letters, Enter runs it.
- `Ctrl+T`: pick a file and paste its path at the cursor. Preview on the right.
- `Alt+C`: pick a directory and cd into it.
- `Tab` after `cd ` or `kubectl ` opens the same fuzzy menu (fzf-tab).

**zoxide** (smarter cd). Replaces the `z` plugin.
- `z argo` jumps to the most-used directory matching "argo".
- `zi` picks interactively.
- It learns from every `cd`, so it gets better over time.

**per-directory-history** (kept). `Ctrl+G` toggles between this directory's
history and global history.

## Files

**eza** (ls). `ls`, `ll`, `la` are aliased. `lt` shows a two-level tree.
Git status shows next to each file inside a repo.

**bat** (cat). `cat file.py` is highlighted. Piping still gives plain text.
`bat -l yaml -` highlights stdin. `man` pages are rendered through bat.

**fd** (find). `fd pattern` searches file names recursively, ignoring `.git`
and `.gitignore` entries. `fd -e py -x black {}` runs a command per match.

**ripgrep** (grep). `rg TODO` searches recursively. `rg -t py "def main"`
restricts by language. `rg -l` lists only file names.

**micro** (nano). Same feel as a GUI editor: `Ctrl+S` save, `Ctrl+Q` quit,
`Ctrl+E` command prompt, `Ctrl+Z` undo, mouse works. `Alt+N` adds a cursor.

## Git

**delta**. `git diff`, `git log -p`, `git blame` are side by side with line
numbers. `n` / `N` jump between files inside the pager.

**lazygit**. `lg` in a repo. `Space` stages a file, `c` commits, `P` pushes,
`s` stashes. `?` shows all keys. Rebase interactively from the commits panel.

**git-flow (AVH)**. `git flow init -d` once per repo. Then:
`git flow feature start name`, `git flow feature finish name`,
`git flow release start 1.2.0`, `git flow release finish 1.2.0`.

## Misc

**pay-respects** (thefuck). After a failing command type `f`.

**sudo plugin**. Press `Esc` twice to put `sudo` in front of the current or
last command.

**copyfile / copypath**. `copyfile settings.py` copies contents,
`copypath` copies the absolute path of the current directory.

**extract**. `x archive.tar.gz` unpacks anything.

**Aliases** worth remembering: `..`, `...`, `-` (previous dir), `dotfiles`,
`reload`, `tf`, `k` (kubectl), `mkvenv`, `uvcompile`, `uvsync`.

## Opt-in plugins (uncomment in zsh/plugins.txt)

- **zsh-abbr**: aliases that expand inline when you press space, so the real
  command lands in history and in what you paste to teammates.
- **zsh-you-should-use**: prints a hint when you type a command that has an
  alias. Good for learning the new aliases, noisy after that.
- **forgit**: fzf menus for `git add`, `git log`, `git stash`. Overlaps with lazygit.
- **atuin**: history in a SQLite database, optionally synced end-to-end
  encrypted across machines. `brew install atuin` first.
```

- [ ] **Step 3: Commit**

```bash
git add README.md docs/TRY.md
git commit -m "Rewrite README; add try-list for new tools

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 12: Migrate this machine and verify

This task changes the live home directory. Every step is reversible via `~/.dotfiles-backup/<timestamp>/` and the untouched `~/.antigen` directory.

- [ ] **Step 1: Run the installer for real**

Run: `cd ~/.dotfiles && ./install --none`
Expected: backup lines for `~/.zprofile`, `~/.zshenv`, `~/.gitconfig`; dotbot success; brew installs the missing CLI formulae (several minutes); casks for apps already in `/Applications` are skipped; `chsh` is skipped because the shell is already zsh; follow-up list printed. Optional groups are declined by `--none`; the user can delete lines from `~/.dotfiles.local` later to be asked.

- [ ] **Step 2: Run the shell checks**

Run: `tests/check-shell.sh`
Expected: five `ok` lines and a startup time. If `zsh startup wrote to stderr` fails, print the stderr block and fix the fragment named in it before continuing.

- [ ] **Step 3: Verify the Python flow in a real project**

```bash
cd ~/projects/argo 2>/dev/null && ls -d */ | head -3
zsh -ilc 'cd ~/projects/argo/$(ls ~/projects/argo | head -1) && echo VENV=$VIRTUAL_ENV; pyenv version; uv --version; virtualenv --version'
```
Expected: `VENV=` shows an activated `~/.virtualenvs/...` path if that project has a `.venv` marker (or empty if not), pyenv reports the local version, uv and virtualenv print versions.

- [ ] **Step 4: Verify git and iTerm2**

```bash
git -C ~/.dotfiles log -1 --stat | head -5
defaults read com.googlecode.iterm2 PrefsCustomFolder
defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder
```
Expected: log renders through delta without error; the two defaults print the repo's `iterm2` path and `1`.

- [ ] **Step 5: Report to the user and wait**

Tell the user to open a new iTerm2 tab and confirm the prompt renders with icons and no errors. Do not delete `~/.antigen` or the backup files until they confirm.

- [ ] **Step 6: After confirmation, clean up and merge**

```bash
rm -rf ~/.antigen ~/.antigen_plugin_lastupdate ~/.antigen_system_lastupdate ~/.antigenrc.zwc ~/.zshrc.zwc
rm -f ~/.zshrc.backup ~/.zprofile.bak ~/.zprofileeval
cd ~/.dotfiles && git checkout master && git merge --ff-only modernize
```
Then ask the user whether to push `master` (pushing triggers CI on GitHub).
