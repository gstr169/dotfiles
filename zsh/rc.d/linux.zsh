# Linux only.
(( $+commands[xdg-open] )) && alias open='xdg-open'
if (( $+commands[xclip] )); then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi
