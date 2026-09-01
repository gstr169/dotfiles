# Dotfiles modernization design

Date: 2026-09-02
Status: approved in discussion, pending written review
Repo: github.com/gstr169/dotfiles

## Goal

Make `~/.dotfiles` reproduce the working environment on a fresh macOS
(Apple Silicon or Intel) or Debian/Ubuntu machine with one command, while
keeping the current daily workflow intact. Windows is out of scope.

## Problems being fixed (from the audit)

- antigen is unmaintained (last commit 2019); cached plugins date from 2022.
- `install` runs `git submodule update --remote`, so installs are not reproducible.
- `config/zshrc` hardcodes `/Users/dmitry_finko/...` paths and mixes Intel and
  Apple Silicon brew prefixes.
- oh-my-zsh flags (`HYPHEN_INSENSITIVE`, `ENABLE_CORRECTION`, `HIST_STAMPS`)
  are set after plugins load and are ignored.
- `~/.zprofile`, `~/.zshenv`, `~/.gitconfig`, `~/.config/git/ignore` are not
  tracked.
- No package manifest for 35 brew formulae and 12 casks.
- `requirements.txt` carries dead tools (`youtube-dl`, `thefuck`) and installs
  `uv` through pip.
- `EDITOR` is unset.

## Decisions made with the user

| Topic | Decision |
|---|---|
| Structure | Keep dotbot; replace antigen with antidote; add Brewfiles; bash bootstrap |
| Linux target | Debian/Ubuntu only (apt) |
| Python | Unchanged flow: pyenv for interpreters (global + per-project local), `virtualenv ~/.virtualenvs/<name> -p X.Y`, `uv pip compile` / `uv pip sync`. uv and virtualenv installed via brew. autoswitch-virtualenv kept, pointed at `~/.virtualenvs` |
| Editor | `EDITOR`/`VISUAL` = micro if present, else nano. Sublime Text and JetBrains Toolbox installed as GUI apps, no tracked config for them |
| CLI tools | fzf, zoxide, eza, bat, ripgrep, fd, git-delta, lazygit, pay-respects, micro |
| GUI apps (macOS) | Required: iTerm2, Sublime Text, JetBrains Toolbox, Docker Desktop, Google Chrome, Enpass, Nerd Font. Optional groups, prompted: Messaging (Slack, Telegram), Notes and AI (Notion, Claude, ChatGPT), Media and cloud (VLC, Google Drive), Network (Tailscale) |
| GUI apps (Linux) | Optional groups, prompted: Browser and editors (Chrome, Sublime, JetBrains Toolbox, Enpass via vendor apt repos/tarball), Messaging (Slack, Telegram via Flatpak), Media (VLC via apt), Network (Tailscale via apt repo), Docker (Docker Engine via apt repo + docker group) |
| Git identity | Personal identity globally; `includeIf gitdir:~/projects/argo/` loads a work identity with a placeholder email |
| SSH | Nothing tracked. Installer only ensures `~/.ssh` exists with mode 700 |
| iTerm2 | Live preferences plist captured into the repo; iTerm2 set to load prefs from that folder |
| Prompt | powerlevel10k with the existing `p10k.zsh` |
| Brew formulae kept | See Brewfile table below. Explicitly kept on request: black, sshpass, git-flow-avh, magic-wormhole |
| Brew formulae dropped | kubernetes-cli@1.22, python@3.9, pipenv, dbml-cli, librdkafka, openblas, oath-toolkit, smartmontools, unbound, nghttp2, miniconda cask |

## Repository layout

```
.dotfiles/
├── bootstrap.sh              # curl-able entry point for a blank machine
├── install                   # dotbot runner; detects OS; no --remote
├── install.conf.yaml         # links and dirs common to both OSes
├── install.macos.yaml        # macOS-only steps
├── install.linux.yaml        # Linux-only steps
├── Brewfile                  # CLI formulae, both OSes
├── Brewfile.macos            # required casks + font
├── Brewfile.macos.optional   # optional casks, grouped by comment markers
├── apt-packages.txt          # Linux prerequisites Linuxbrew cannot provide
├── linux-gui/                # one script per optional Linux GUI group
├── macos-defaults.sh         # optional, prompted
├── zsh/
│   ├── zshenv                # -> ~/.zshenv
│   ├── zprofile              # -> ~/.zprofile
│   ├── zshrc                 # -> ~/.zshrc
│   ├── plugins.txt           # antidote bundle list
│   ├── p10k.zsh              # existing theme config, moved from shell/
│   └── rc.d/
│       ├── 00-options.zsh
│       ├── 10-path.zsh
│       ├── 20-tools.zsh
│       ├── 30-aliases.zsh
│       ├── 40-python.zsh
│       ├── macos.zsh
│       └── linux.zsh
├── git/
│   ├── gitconfig             # -> ~/.gitconfig
│   ├── gitconfig-argo        # work identity, placeholder email
│   └── gitignore_global      # -> ~/.config/git/ignore
├── config/
│   ├── micro/settings.json   # -> ~/.config/micro/settings.json
│   └── lazygit/config.yml    # -> ~/.config/lazygit/config.yml
├── iterm2/com.googlecode.iterm2.plist
├── docs/
│   ├── TRY.md                # try-list for the new tools
│   └── superpowers/specs/    # this document
├── .github/workflows/ci.yml
├── dotbot/                   # submodule, pinned
├── antidote/                 # submodule, pinned
├── .gitignore
└── README.md
```

Removed from the repo: `antigen/` and `dotbot-pip/` submodules, `config/`
(old zshrc and antigenrc), `shell/`, `requirements.txt`,
`install_pip.conf.yaml`, `iterm_conf/iTerm2 State.itermexport`.

Home directory files remain symlinks into the repo. Dotbot `clean` with
`force: true` removes the stale `~/.antigen.zsh`, `~/.antigenrc` and
`~/.shell` links.

## Shell configuration

### Load order

1. `zshenv`: environment for all shell types only. `EDITOR`/`VISUAL`
   (micro then nano), XDG base dirs, cargo env if present, `LANG`.
   Sources `~/.zshenv.local` if present.
2. `zprofile` (login shells): `brew shellenv` from whichever prefix exists
   (`/opt/homebrew`, `/usr/local`, `/home/linuxbrew/.linuxbrew`),
   `pyenv init --path`, JetBrains Toolbox scripts dir if present.
3. `zshrc` (interactive):
   1. p10k instant prompt block (must stay first).
   2. `rc.d/00-options.zsh`: history and completion options, oh-my-zsh flags.
      These run before plugins so oh-my-zsh honours them.
   3. antidote: `source antidote/antidote.zsh; antidote load zsh/plugins.txt`.
      antidote writes a static bundle file to `~/.cache/antidote/` and
      rebuilds it only when `plugins.txt` changes.
   4. `rc.d/10-path.zsh`, `20-tools.zsh`, `30-aliases.zsh`, `40-python.zsh`.
   5. `rc.d/macos.zsh` or `rc.d/linux.zsh` by `$OSTYPE`.
   6. `zsh/p10k.zsh`.
   7. `~/.zshrc.local` if present.

### Options (00-options.zsh)

`AUTO_CD`, `EXTENDED_HISTORY`, `HIST_IGNORE_ALL_DUPS`, `HIST_IGNORE_SPACE`,
`SHARE_HISTORY`, `INTERACTIVE_COMMENTS`, `HISTSIZE=SAVEHIST=100000`,
`HIST_STAMPS="yyyy-mm-dd"`, `ENABLE_CORRECTION="true"`,
`HYPHEN_INSENSITIVE="false"`, `DISABLE_AUTO_UPDATE="true"` (antidote manages
updates), `zstyle` for case-insensitive completion matching.

### Plugins (plugins.txt)

Kept from antigenrc: oh-my-zsh lib; oh-my-zsh plugins `git`, `docker`,
`docker-compose`, `extract`, `pip`, `python`, `pyenv`, `brew`, `direnv`,
`colored-man-pages`, `macos` (conditional on Darwin); `zsh-users/zsh-autosuggestions`;
`zsh-users/zsh-completions`; `z-shell/F-Sy-H`; `djui/alias-tips`;
`CyberShadow/per-directory-history`; `MichaelAquilina/zsh-autoswitch-virtualenv`;
`romkatv/powerlevel10k`.

Added: oh-my-zsh `kubectl`, `helm`, `terraform`, `gh`, `sudo`, `copyfile`,
`copypath`; `Aloxaf/fzf-tab`.

Dropped: `history`, `sublime`, `thefuck`, `colorize`, the poetry custom plugin.

Opt-in, present but commented out: `olets/zsh-abbr`, `atuinsh/atuin`,
`MichaelAquilina/zsh-you-should-use`, `wfxr/forgit`.

Load order inside the file: oh-my-zsh lib first, then plugins, then
completions, then F-Sy-H and autosuggestions last, then the theme, per
each plugin's documented requirement.

### Tools (20-tools.zsh)

Every block is guarded with `(( $+commands[tool] ))`. Missing tools produce
no output.

- pyenv: `eval "$(pyenv init - zsh)"`.
- fzf: `source <(fzf --zsh)`; Ctrl+R history, Ctrl+T files, Alt+C dirs.
  `FZF_DEFAULT_COMMAND` uses `fd` when present.
- zoxide: `eval "$(zoxide init zsh --cmd z)"`.
- direnv: `eval "$(direnv hook zsh)"`.
- gcloud: source `$HOME/google-cloud-sdk/{path,completion}.zsh.inc` if the
  directory exists. `CLOUDSDK_PYTHON` is not set; README notes how to set it
  in `~/.zshrc.local` if gcloud needs a specific interpreter.
- kubectl, helm, gh: completions loaded lazily on first use.
- pay-respects: `eval "$(pay-respects zsh --alias f)"`.
- Go: `GOPATH=$HOME/go`, `$GOPATH/bin` on PATH. `GOROOT` is not exported;
  brew's go finds its own root.

### PATH (10-path.zsh)

Built once with `typeset -U path` to deduplicate. Prepends in this order:
`$HOME/.local/bin`, `$HOME/bin`, `$(brew --prefix)/opt/libpq/bin` if present,
`$(brew --prefix)/opt/openssl@3/bin` if present, `$HOME/go/bin`,
`$HOME/.cargo/bin`. `brew --prefix` is called once and cached in
`HOMEBREW_PREFIX` by `brew shellenv` in zprofile, so no subprocess here.

`LDFLAGS`/`CPPFLAGS` for psycopg2 builds are set only when the openssl and
zlib brew kegs exist, using `$HOMEBREW_PREFIX`.

### Python (40-python.zsh)

- `VIRTUALENV_HOME=$HOME/.virtualenvs`, `AUTOSWITCH_VIRTUAL_ENV_DIR` set to it,
  `AUTOSWITCH_SILENT=1`.
- `mkvenv <name> <pyver>`: runs `virtualenv "$VIRTUALENV_HOME/$name" -p "$pyver"`
  and writes `.venv` containing `<name>` in the current directory so
  autoswitch activates it.
- `uvsync`: runs `uv pip sync` over `requirements/requirements.txt` and
  `requirements/dev-requirements.txt` when they exist, otherwise
  `requirements.txt`.
- `uvcompile`: runs `uv pip compile requirements/requirements.in -o
  requirements/requirements.txt` when the `.in` file exists.
  All three are conveniences; the underlying commands are unchanged.

### Aliases (30-aliases.zsh)

- `ls`, `ll`, `la`, `lt` (tree) to `eza` with `--git --icons`, guarded.
- `cat` to `bat --paging=never --style=plain` when interactive; `bat` sets
  `BAT_THEME`. Piped output is unaffected because bat detects non-tty.
- `lg` = lazygit, `x` = extract, `..`/`...`/`....`, `-` = `cd -`,
  `tf` = terraform, `k` from the kubectl plugin.
- `grep` and `find` are not aliased.

## Packages

### Brewfile (both OSes)

| Group | Formulae |
|---|---|
| Shell and CLI | zsh, git, git-lfs, micro, fzf, zoxide, eza, bat, ripgrep, fd, git-delta, lazygit, pay-respects, jq, tree, wget, sevenzip, age, sops, rclone, magic-wormhole, yt-dlp, ffmpeg, nmap, git-flow-avh, sshpass |
| Python | pyenv, virtualenv, uv, black, python@3.13 |
| Go and Rust | go, rustup |
| Cloud and k8s | awscli, awscurl, kubernetes-cli, helm, k9s, stern, gh |
| Databases | libpq, postgresql@14 |

### Brewfile.macos (required)

Casks: iterm2, sublime-text, jetbrains-toolbox, docker (Docker Desktop),
google-chrome, enpass, font-meslo-lg-nerd-font.

### Brewfile.macos.optional

Groups delimited by `# group: <name>` comments so the installer can present
each group as a prompt:

- Messaging: slack, telegram
- Notes and AI: notion, claude, chatgpt
- Media and cloud: vlc, google-drive
- Network: tailscale

### apt-packages.txt (Linux prerequisites)

`build-essential`, `zsh`, `git`, `curl`, `file`, `procps`, `ca-certificates`,
`gnupg`, `nano`.

### linux-gui/ (Linux optional groups)

One script per group, each idempotent:

- `browser-editors.sh`: Google Chrome (Google apt repo), Sublime Text
  (Sublime apt repo), JetBrains Toolbox (official tarball to
  `~/.local/share/JetBrains/Toolbox`), Enpass (Enpass apt repo).
- `messaging.sh`: installs flatpak + Flathub remote if missing; Slack,
  Telegram.
- `media.sh`: VLC via apt.
- `network.sh`: Tailscale via its apt repo.
- `docker.sh`: Docker Engine + compose plugin via Docker apt repo; adds the
  user to the `docker` group.

Not offered on Linux (no official package): Notion, Claude desktop, ChatGPT
desktop, Google Drive. The installer prints this list once.

### Not managed

gcloud SDK (manual install to `$HOME/google-cloud-sdk`, as today), pyenv
Python versions (`pyenv install` after setup), JetBrains IDEs (via Toolbox),
Docker Desktop on Linux.

## Install flow

### bootstrap.sh

Runs on a blank machine via `curl | bash`, or locally. Steps, each skipped
when already satisfied:

1. Detect OS. Abort with a message on anything other than Darwin or a
   Debian-family Linux.
2. macOS: `xcode-select --install` if CLT missing, wait for completion.
   Linux: `sudo apt-get update && apt-get install` from `apt-packages.txt`.
3. Install Homebrew if `brew` is not found (official installer, non-interactive
   with `NONINTERACTIVE=1`). Eval `brew shellenv` for the rest of the run.
4. Clone `github.com/gstr169/dotfiles` to `~/.dotfiles` with
   `--recurse-submodules`, or `git pull --recurse-submodules` if it exists.
   Uses HTTPS so no SSH key is required on a fresh machine.
5. `exec ~/.dotfiles/install "$@"`.

Flags: `--all` (accept every optional group), `--none` (decline all),
`--no-gui`. Flags pass through to `install`.

### install

1. Parse flags. Load remembered answers from `~/.dotfiles.local` (a
   `key=value` file, untracked).
2. `dotbot -c install.conf.yaml`: clean stale links, link zsh/git/config
   files, create `~/projects`, `~/.virtualenvs`, `~/.ssh` (mode 700),
   `~/.config/micro`, `~/.config/lazygit`.
3. `brew bundle --file Brewfile --no-lock`.
4. macOS: pre-scan `/Applications` for each cask in `Brewfile.macos` and
   `Brewfile.macos.optional`; any app present but not brew-managed is written
   to a temporary filtered Brewfile exclusion so `brew bundle` skips it.
   Then `brew bundle --file Brewfile.macos`.
5. Optional groups: for each group not already answered in
   `~/.dotfiles.local`, print the apps and ask `[y/N]`. Save the answer.
   macOS: build a temporary Brewfile from accepted groups and run
   `brew bundle`. Linux: run the accepted `linux-gui/*.sh` scripts.
6. macOS: `dotbot -c install.macos.yaml`: set iTerm2 `PrefsCustomFolder` to
   `~/.dotfiles/iterm2` and `LoadPrefsFromCustomFolder` true; offer
   `macos-defaults.sh` as one more remembered prompt.
   Linux: `dotbot -c install.linux.yaml` (currently only Linux-specific
   links; placeholder for growth).
7. `chsh`: if `$SHELL` is not zsh, add brew's zsh to `/etc/shells` when
   missing (macOS), then `chsh -s <zsh>`. Skipped in CI via `--no-chsh`.
8. Print the manual follow-up list:
   - copy SSH keys and `~/.ssh/config` from the old machine
   - set the work email in `git/gitconfig-argo`
   - `pyenv install <versions>` and `pyenv global <version>`
   - sign in to JetBrains Toolbox and install PyCharm/GoLand
   - install gcloud SDK if needed
   - on Linux, log out and in for the docker group
   - open a new terminal; antidote builds its bundle on first start

Re-running `install` is safe and fast: dotbot relinks, brew bundle is a
no-op, remembered prompts are not re-asked.

### Migration on this machine

The existing `~/.antigen` directory and `~/.zshrc.backup`, `~/.zprofile.bak`,
`~/.zprofileeval`, `~/.bash_profile` are not touched by the installer. After
the user confirms the new shell works, a documented cleanup step removes them.

## Git

`git/gitconfig`:

- `[user]` name `dmitry.finko`, email `dmit.finn@yandex.ru`.
- `init.defaultBranch=main`, `pull.rebase=true`, `push.autoSetupRemote=true`,
  `rerere.enabled=true`, `fetch.prune=true`, `diff.colorMoved=default`.
- `core.pager=delta`, `interactive.diffFilter=delta --color-only`,
  `delta.side-by-side=true`, `delta.line-numbers=true`, `delta.navigate=true`.
- `core.excludesfile=~/.config/git/ignore`.
- `[includeIf "gitdir:~/projects/argo/"] path=~/.dotfiles/git/gitconfig-argo`.
- `[include] path=~/.gitconfig.local` (ignored if missing).

`git/gitconfig-argo`: `user.email=CHANGE_ME@work.example`,
`core.sshCommand=ssh -i ~/.ssh/argo_id_rsa`. The placeholder is called out in
the install follow-ups.

`git/gitignore_global`: `.DS_Store`, `.idea/`, `.vscode/`, `.venv/`, `venv/`,
`__pycache__/`, `*.pyc`, `.env.local`, `**/.claude/settings.local.json`.

## Editors and terminal

- `config/micro/settings.json`: `tabsize 4`, `tabstospaces true`,
  `rmtrailingws true`, `mouse true`, `softwrap true`, `colorscheme` set to a
  dark scheme compatible with the p10k palette.
- `config/lazygit/config.yml`: `git.paging.pager: delta --dark --paging=never`,
  `gui.showIcons: true`.
- `iterm2/com.googlecode.iterm2.plist`: exported from this machine at
  implementation time with `defaults export com.googlecode.iterm2`.
  iTerm2 is set to read and write this folder, so later changes appear as
  git diffs. The font entry is verified to be `MesloLGS NF`.
- `macos-defaults.sh`: `KeyRepeat 2`, `InitialKeyRepeat 15`,
  `ApplePressAndHoldEnabled false`, Finder `AppleShowAllFiles` and
  `AppleShowAllExtensions` true, then restart Finder.

## Documentation

- `README.md`: one-line bootstrap, install flags, table of what is installed
  per OS, optional groups, manual follow-ups, how to add a brew package or a
  zsh plugin, how iTerm2 settings sync, local override files, cleanup after
  migration, short history note crediting mom1/dotfiles.
- `docs/TRY.md`: per tool, the first two or three commands worth learning,
  ordered by expected payoff: fzf key bindings, zoxide, eza, bat, ripgrep,
  fd, delta, lazygit, micro, pay-respects, git-flow starter recipe,
  new aliases and the sudo/copyfile/copypath plugins, then the opt-in plugins
  (zsh-abbr, atuin, you-should-use, forgit) with how to enable each.

## Verification

### CI (`.github/workflows/ci.yml`)

Triggers on push and pull request. Two jobs: `macos-latest` and
`ubuntu-latest`. Each:

1. Checks out with submodules.
2. Runs `./bootstrap.sh --none --no-gui --no-chsh` (repo already present, so
   bootstrap's clone step is a no-op).
3. Runs `zsh -ilc 'exit'` and fails on any stderr output.
4. Asserts `command -v fzf eza bat rg fd zoxide uv pyenv micro lazygit`
   succeed inside `zsh -ilc`.
5. Asserts `git config user.email` equals the personal address and that
   `git -C <tmp under ~/projects/argo/> config user.email` returns the
   placeholder.
6. macOS job skips `Brewfile.macos` casks via `--no-gui` to stay under the
   runner time budget.

### Local

Before committing the switch, on this machine:

1. Run `./install --none` in a scratch `HOME` to check it completes without
   touching the real home.
2. Run `./install` for real.
3. Open a new iTerm2 tab; confirm no errors, prompt renders with icons,
   `pyenv versions`, `uv --version`, autoswitch activates a known venv,
   startup time stays near 0.2 s (`time zsh -ic exit`).
4. Confirm `git log` uses delta and a commit under `~/projects/argo/`
   reports the placeholder email.

## Out of scope

Windows, secrets management, IDE settings sync, Docker Desktop on Linux,
managing pyenv-installed Python versions, non-Debian Linux.
