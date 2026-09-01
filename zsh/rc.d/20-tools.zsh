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
