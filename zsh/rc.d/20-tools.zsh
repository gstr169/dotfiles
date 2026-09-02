# Tool integrations. Every block is guarded: a missing binary prints nothing.
# The pyenv hook comes from its Oh My Zsh plugin (plugins.txt).

# direnv: hand-rolled hook instead of `direnv hook zsh` / the OMZ plugin. direnv's own
# hook wraps the export in `trap '' SIGINT` ... `trap - SIGINT` inside precmd, and with
# zsh-defer-loaded plugins (F-Sy-H, autosuggestions) that leaves Up-arrow stuck on the
# newest history entry after a Ctrl+C.
if (( $+commands[direnv] )); then
  _direnv_hook() { eval "$(direnv export zsh)" }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _direnv_hook
  add-zsh-hook chpwd _direnv_hook
fi

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
if (( $+commands[pay-respects] )); then
  eval "$(pay-respects zsh --alias f)"
  # Its hook re-expands $PROMPT with `print -P`, which fails on powerlevel10k's prompt
  # ("__pr_base:1: bad substitution"). Same function without the prompt prefix.
  __pr_base() {
    _PR_MODE="$1" _PR_PREFIX="" _PR_LAST_COMMAND="$2" _PR_ALIAS="$(alias)" _PR_SHELL="zsh" pay-respects
  }
fi

# Google Cloud SDK, manual install location.
if [[ -d "$HOME/google-cloud-sdk" ]]; then
  [[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
  [[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi
