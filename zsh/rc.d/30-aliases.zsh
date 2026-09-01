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
