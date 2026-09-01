# PATH assembly. brew shellenv (zprofile) already set HOMEBREW_PREFIX and brew paths.
typeset -U path fpath   # keep entries unique

path=("$HOME/.local/bin" "$HOME/bin" $path)

if [[ -n "$HOMEBREW_PREFIX" ]]; then
  [[ -d "$HOMEBREW_PREFIX/opt/libpq/bin" ]] && path=("$HOMEBREW_PREFIX/opt/libpq/bin" $path)

  # Build flags so psycopg2 and friends find brew's openssl/zlib.
  if [[ -d "$HOMEBREW_PREFIX/opt/openssl@3" && -d "$HOMEBREW_PREFIX/opt/zlib" ]]; then
    export LDFLAGS="-L$HOMEBREW_PREFIX/opt/openssl@3/lib -L$HOMEBREW_PREFIX/opt/zlib/lib"
    export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/openssl@3/include -I$HOMEBREW_PREFIX/opt/zlib/include"
  fi
fi

export GOPATH="${GOPATH:-$HOME/go}"
[[ -d "$GOPATH/bin" ]] && path+=("$GOPATH/bin")
[[ -d "$HOME/.cargo/bin" ]] && path+=("$HOME/.cargo/bin")

# Non-login interactive shells (e.g. `zsh` typed in a terminal) skip zprofile.
if [[ -z "$EDITOR" ]]; then
  (( $+commands[micro] )) && export EDITOR=micro || export EDITOR=nano
  export VISUAL="$EDITOR"
fi
