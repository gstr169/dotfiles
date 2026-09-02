# Key bindings that must come AFTER plugins (Oh My Zsh lib/key-bindings sets its own).

# Up/Down: prefix history search that is stateless. Oh My Zsh binds
# up-line-or-beginning-search, which only keeps walking back when the previous widget
# was itself; in this setup something runs between key presses and the second Up
# re-searched the recalled line, leaving Up stuck on the newest entry.
# history-beginning-search-* keep the cursor where it was, so the typed prefix is kept.
for _k in '^[[A' '^[OA'; do bindkey "$_k" history-beginning-search-backward; done
for _k in '^[[B' '^[OB'; do bindkey "$_k" history-beginning-search-forward; done
unset _k
