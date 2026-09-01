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

Apps already present in `/Applications` are skipped, even if they were not
installed with brew.

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
