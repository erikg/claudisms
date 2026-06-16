#!/bin/bash
# Reset window status bar when user submits response
if [ -n "$TMUX_PANE" ]; then
  tmux set-window-option -t "$TMUX_PANE" window-status-style default
  tmux set-window-option -t "$TMUX_PANE" window-status-current-style default
fi
