# macOS only.
export HOMEBREW_NO_ENV_HINTS=1
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'

# git-flow (AVH) needs GNU getopt for long options; brew's gnu-getopt is keg-only.
if [[ -x "$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" ]]; then
  export FLAGS_GETOPT_CMD="$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt"
fi
