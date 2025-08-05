#!/bin/bash

selection=$(fzf --reverse --no-sort \
    --ansi \
    --header="🧠 tmux cheat sheet — type to filter, ESC to quit" \
    --with-nth=1..2 \
    --delimiter='|' \
    --preview='cut -d"|" -f3- <<< {}' \
    < "$HOME/.config/tmux/cheatsheet")

# Extract the command from column 2
cmd=$(cut -d'|' -f2 <<< "$selection" | xargs)

# If a command was selected, run it *as a tmux command*
[ -n "$cmd" ] && tmux run-shell "tmux $cmd"

exit 0
