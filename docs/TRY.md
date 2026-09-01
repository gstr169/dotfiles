# Things to try

Ordered by expected payoff. Each entry: what it replaces, the two or three
commands worth learning first.

## Shell navigation

**fzf** (fuzzy finder). Replaces scrolling through history.
- `Ctrl+R`: fuzzy search history. Type a few letters, Enter runs it.
- `Ctrl+T`: pick a file and paste its path at the cursor. Preview on the right.
- `Alt+C`: pick a directory and cd into it.
- `Tab` after `cd ` or `kubectl ` opens the same fuzzy menu (fzf-tab).

**zoxide** (smarter cd). Replaces the `z` plugin.
- `z argo` jumps to the most-used directory matching "argo".
- `zi` picks interactively.
- It learns from every `cd`, so it gets better over time.

**per-directory-history** (kept). `Ctrl+G` toggles between this directory's
history and global history.

## Files

**eza** (ls). `ls`, `ll`, `la` are aliased. `lt` shows a two-level tree.
Git status shows next to each file inside a repo.

**bat** (cat). `cat file.py` is highlighted. Piping still gives plain text.
`bat -l yaml -` highlights stdin. `man` pages are rendered through bat.

**fd** (find). `fd pattern` searches file names recursively, ignoring `.git`
and `.gitignore` entries. `fd -e py -x black {}` runs a command per match.

**ripgrep** (grep). `rg TODO` searches recursively. `rg -t py "def main"`
restricts by language. `rg -l` lists only file names.

**micro** (nano). Same feel as a GUI editor: `Ctrl+S` save, `Ctrl+Q` quit,
`Ctrl+E` command prompt, `Ctrl+Z` undo, mouse works. `Alt+N` adds a cursor.

## Git

**delta**. `git diff`, `git log -p`, `git blame` are side by side with line
numbers. `n` / `N` jump between files inside the pager.

**lazygit**. `lg` in a repo. `Space` stages a file, `c` commits, `P` pushes,
`s` stashes. `?` shows all keys. Rebase interactively from the commits panel.

**git-flow (AVH)**. `git flow init -d` once per repo. Then:
`git flow feature start name`, `git flow feature finish name`,
`git flow release start 1.2.0`, `git flow release finish 1.2.0`.

## Misc

**pay-respects** (thefuck). After a failing command type `f`.

**sudo plugin**. Press `Esc` twice to put `sudo` in front of the current or
last command.

**copyfile / copypath**. `copyfile settings.py` copies contents,
`copypath` copies the absolute path of the current directory.

**extract**. `x archive.tar.gz` unpacks anything.

**Aliases** worth remembering: `..`, `...`, `-` (previous dir), `dotfiles`,
`reload`, `tf`, `k` (kubectl), `mkvenv`, `uvcompile`, `uvsync`.

## Opt-in plugins (uncomment in zsh/plugins.txt)

- **zsh-abbr**: aliases that expand inline when you press space, so the real
  command lands in history and in what you paste to teammates.
- **zsh-you-should-use**: prints a hint when you type a command that has an
  alias. Good for learning the new aliases, noisy after that.
- **forgit**: fzf menus for `git add`, `git log`, `git stash`. Overlaps with lazygit.
- **atuin**: history in a SQLite database, optionally synced end-to-end
  encrypted across machines. `brew install atuin` first.
