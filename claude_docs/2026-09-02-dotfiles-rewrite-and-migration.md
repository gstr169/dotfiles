# 2026-09-02: dotfiles rewrite and new-Mac migration

Session log, written by Claude Code at the end of the day. Design and plan documents
are in `docs/superpowers/`; this is the short version of what happened and why.

## Outcome

- `~/.dotfiles` now installs a full environment on a blank macOS or Debian/Ubuntu machine
  with one command (`bootstrap.sh`), and re-runs are idempotent (`./install`).
- Verified on: the old M1 Mac (in place), the new Mac (fresh install), and GitHub Actions
  on `macos-latest` and `ubuntu-latest` (CI is green on every commit since the rewrite).
- This Claude Code session itself was moved from the old Mac to the new one mid-day by
  copying `~/.claude` and `~/Library/Application Support/Claude/claude-code-sessions`.

## What changed

| Area | Before | After |
|---|---|---|
| Plugin manager | antigen (dead since 2019, plugins cached from 2022) | antidote v2.3.0 via `getantidote/use-omz`, pinned submodule |
| Shell config | one `zshrc` with hardcoded `/Users/...` paths | `zsh/zshenv`, `zprofile`, `zshrc` + ordered `zsh/rc.d/*.zsh`, all guarded by `command -v` |
| Packages | none tracked | `Brewfile` (CLI, both OSes), `Brewfile.macos` (required casks), `Brewfile.macos.optional` (prompted groups), `apt-packages.txt`, `linux-gui/*.sh` |
| Installer | dotbot + `--remote` submodules | `bootstrap.sh` → `install`: dotbot, brew bundle (never upgrades), remembered prompts in `~/.dotfiles.local`, font, git-flow from source, cargo tools, chsh |
| Git | untracked `~/.gitconfig` | `git/gitconfig` with delta, `includeIf` for `~/projects/argo/` → `git/gitconfig-argo` → untracked `~/.gitconfig-argo.local` (work email never in the repo) |
| Editor | `EDITOR` unset | micro, nano fallback |
| iTerm2 | stale export file | live plist in `iterm2/`, iTerm2 reads/writes it directly |
| Verification | none | `tests/check-shell.sh` + `.github/workflows/ci.yml` |
| Docs | 2021 README | README, `docs/TRY.md` (new tools cheat sheet) |

Kept unchanged on request: pyenv + `virtualenv ~/.virtualenvs/<name>` + `uv pip compile/sync`
flow, powerlevel10k, per-directory-history, black as a brew binary, sshpass, magic-wormhole.

## Bugs found on the way (and their fixes)

1. **Homebrew removed `git-flow-avh`** and deprecated `git-flow`. Installer now builds the
   AVH edition from source into `~/.local/bin`; `gnu-getopt` + `FLAGS_GETOPT_CMD` on macOS.
2. **`brew bundle` upgrades casks by default** and needed sudo for Docker Desktop, which
   quit Docker mid-install. `HOMEBREW_BUNDLE_NO_UPGRADE=1` in `install`.
3. **Hand-installed and App Store apps** (Enpass, Chrome, ...) made cask installs fail.
   `scripts/cask-skip.sh` detects them by artifact, display name, or pkg receipt.
4. **Debian's `/etc/zsh/zshrc` runs a bare `compinit`** before `~/.zshrc`; with Linuxbrew's
   group-writable completion dir it aborts. `skip_global_compinit=1` in `zshenv` plus the
   documented `chmod -R go-w` in `install`.
5. **The brew Nerd Font cask is not the font the iTerm2 profile uses.** Installer downloads
   powerlevel10k's `MesloLGS NF` files directly.
6. **direnv's shell hook wraps precmd in `trap '' SIGINT`/`trap - SIGINT`**; with
   zsh-defer-loaded plugins this broke Up-arrow after a Ctrl+C. Hand-written trap-free hook.
7. **Up-arrow stuck on the newest history line in iTerm2** (never reproducible in scripted
   terminals): OMZ's `up-line-or-beginning-search` depends on `LASTWIDGET` continuity that
   something in this plugin set breaks. Bound Up/Down to the stateless
   `history-beginning-search-backward/forward` (`zsh/rc.d/50-keys.zsh`).
8. **`cat` aliased to bat** broke `cat -v`. Alias removed.
9. **eza ≥0.23 treats `--icons` as taking a value**, so `ls <path>` failed. `--icons=auto`.
10. **brew's rustup is keg-only**; cargo was invisible to the shell and the installer.
    Both now add `$(brew --prefix)/opt/rustup/bin`. pay-respects needs Rust ≥1.85.
11. **Auto-correction** had been configured for years but never active (set after plugins
    loaded); enabling it for real was unwanted, so it is now explicitly off.

## Machine notes

- Old Mac: Docker Desktop upgraded 3.5.2 → 4.89, Rust 1.50 → 1.98 (`rustup update stable`),
  old antigen state removed. Needs `git -C ~/.dotfiles pull` and its own
  `~/.gitconfig-argo.local` next time it is used.
- New Mac: Python 3.13 global, new ed25519 keys `~/.ssh/{github,argo,home}` with passphrases
  in Keychain (`Host *` block added by `install`), projects rsynced from the old Mac,
  Claude Code sessions moved. GitHub key registered and remote switched to SSH.

## Open items

- Terraform is not installed by anything (project + completion plugin exist).
- GitLab (`argo`) and home-host public keys still to be registered from the new Mac.
- Docker Desktop not yet launched on the new Mac; gcloud not installed (manual, optional).
- History files: `HIST_IGNORE_ALL_DUPS` dedups on rewrite; a few `echo MARK_... | rev` test
  lines from the Up-arrow investigation remain in the old Mac's history.
- Startup time went from 0.2 s to ~0.4 s (kubectl/helm completion, fzf-tab); acceptable,
  p10k instant prompt hides it.
