# macOS only.
export HOMEBREW_NO_ENV_HINTS=1
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
