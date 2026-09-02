# Shell options and Oh My Zsh flags. Sourced BEFORE plugins load so OMZ honours them.

# History
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY       # timestamps in history
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicates
setopt HIST_IGNORE_SPACE      # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY          # share across tabs (do not add INC_APPEND_HISTORY as well)

# Navigation
setopt AUTO_CD                # `dirname` == `cd dirname`
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS   # allow `# comment` on the command line

# Oh My Zsh flags (read by lib/ when it loads)
HIST_STAMPS="yyyy-mm-dd"
ENABLE_CORRECTION="false"   # was set in the old config but never took effect; keep old behaviour
HYPHEN_INSENSITIVE="false"
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
zstyle ':omz:update' mode disabled

# Plugin settings
PER_DIRECTORY_HISTORY_TOGGLE='^G'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Helpers referenced by `conditional:` annotations in plugins.txt
is-macos() { [[ "$OSTYPE" == darwin* ]] }
is-linux() { [[ "$OSTYPE" == linux* ]] }
