#!/bin/bash
# Turn window red in status bar when Claude asks a question
if [ -n "$TMUX_PANE" ]; then
  tmux set-window-option -t "$TMUX_PANE" window-status-style 'bg=red'
  tmux set-window-option -t "$TMUX_PANE" window-status-current-style 'bg=red'
fi
# Send bell for outer tmux cascading (propagates through SSH)
printf '\a'
