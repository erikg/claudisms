#!/bin/bash
# Clear the red alert when the user re-engages (submits a prompt).
# Unset (-u) the window-local override rather than forcing 'default': stop.sh set
# a window-specific style, so removing it reverts to whatever your global
# window-status-style is — forcing 'default' would instead clobber a themed
# status bar back to terminal-default. (No-op cleanly if no override is set.)
if [ -n "$TMUX_PANE" ]; then
  tmux set-window-option -u -t "$TMUX_PANE" window-status-style
  tmux set-window-option -u -t "$TMUX_PANE" window-status-current-style
fi
