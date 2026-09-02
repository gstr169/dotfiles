# macOS only.
export HOMEBREW_NO_ENV_HINTS=1
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'

# git-flow (AVH) needs GNU getopt for long options; brew's gnu-getopt is keg-only.
if [[ -x "$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt" ]]; then
  export FLAGS_GETOPT_CMD="$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt"
fi

# temp: one-line temperature / power / core usage snapshot (Apple Silicon, via macmon).
# Run `macmon` alone for a live dashboard.
temp() {
  (( $+commands[macmon] )) || { print -u2 "temp: macmon not installed (brew install macmon)"; return 1 }
  macmon pipe -s 1 | jq -r '
    "CPU \(.temp.cpu_temp_avg|round)°C  GPU \(.temp.gpu_temp_avg|round)°C  |  " +
    "power: CPU \(.cpu_power*10|round/10)W  GPU \(.gpu_power*10|round/10)W  system \(.sys_power*10|round/10)W  |  " +
    "busy: E-cores \(.ecpu_usage[1]*100|round)%  P-cores \(.pcpu_usage[1]*100|round)%  GPU \(.gpu_usage[1]*100|round)%"'
}
