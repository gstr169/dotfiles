# Python workflow: pyenv (interpreters) + virtualenv in ~/.virtualenvs + uv (compile/sync).
# The underlying commands are unchanged; these are shortcuts.

export VIRTUALENV_HOME="${VIRTUALENV_HOME:-$HOME/.virtualenvs}"
export AUTOSWITCH_VIRTUAL_ENV_DIR="$VIRTUALENV_HOME"
export AUTOSWITCH_SILENT=1

# mkvenv <name> <python-version>
#   virtualenv ~/.virtualenvs/<name> -p <version>, then write .venv so autoswitch activates it.
mkvenv() {
  if [[ $# -ne 2 ]]; then
    print -u2 "usage: mkvenv <name> <python-version>   e.g. mkvenv argo-backend-3.11 3.11"
    return 2
  fi
  local name="$1" pyver="$2"
  virtualenv "$VIRTUALENV_HOME/$name" -p "$pyver" || return
  print -r -- "$name" > .venv
  print "created $VIRTUALENV_HOME/$name and wrote .venv"
}

# uvcompile: requirements/requirements.in -> requirements/requirements.txt (or top-level).
uvcompile() {
  if [[ -f requirements/requirements.in ]]; then
    uv pip compile requirements/requirements.in -o requirements/requirements.txt "$@"
  elif [[ -f requirements.in ]]; then
    uv pip compile requirements.in -o requirements.txt "$@"
  else
    print -u2 "uvcompile: no requirements.in found"; return 1
  fi
}

# uvsync: install exactly what the compiled files say.
uvsync() {
  local -a files
  [[ -f requirements/requirements.txt ]] && files+=(requirements/requirements.txt)
  [[ -f requirements/dev-requirements.txt ]] && files+=(requirements/dev-requirements.txt)
  (( $#files )) || { [[ -f requirements.txt ]] && files=(requirements.txt) }
  (( $#files )) || { print -u2 "uvsync: no requirements files found"; return 1 }
  uv pip sync "${files[@]}" "$@"
}
