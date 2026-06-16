# claudisms

Small, portable bits of Claude Code tooling and hard-won notes — the kind of
thing that otherwise lives buried in `~/.claude/` and gets lost on the next
machine. Each subdirectory is one self-contained gadget: the script(s) plus a
README explaining what it does, how to wire it in, and *why* the defaults are
what they are.

## Contents

| Entry | What it is |
|---|---|
| [`statusline-context-gauge/`](statusline-context-gauge/) | Live context-window fill gauge for the Claude Code status line (the desktop app's filling-circle, in the terminal). Color warns on *absolute* token load, not just % of window. |
