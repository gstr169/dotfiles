# Aliases. grep and find are deliberately NOT aliased (rg/fd have different flags).

if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -l --group-directories-first --icons=auto --git'
  alias la='eza -la --group-directories-first --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ll='ls -lh'
  alias la='ls -lAh'
fi

# cat is NOT aliased to bat: bat rejects standard cat flags such as -v and -A.
# Use `bat file` for highlighting; `cat` stays the real cat.

(( $+commands[lazygit] )) && alias lg='lazygit'
(( $+commands[terraform] )) && alias tf='terraform'
alias x='extract'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias dotfiles='cd "$DOTFILES"'
alias reload='exec zsh'
