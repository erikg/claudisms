# claudisms

[![shellcheck](https://github.com/erikg/claudisms/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/erikg/claudisms/actions/workflows/shellcheck.yml)

Small, portable bits of Claude Code tooling and hard-won notes — the kind of
thing that otherwise lives buried in `~/.claude/` and gets lost on the next
machine. Each subdirectory is one self-contained gadget: the script(s) plus a
README explaining what it does, how to wire it in, and *why* the defaults are
what they are.

## Install

See **[INSTALL.md](INSTALL.md)** for a deterministic, idempotent recipe that
installs (or updates) every gadget at once — written so a human or Claude Code
can run it verbatim. Each gadget's own README also has a standalone `Install`
section.

## Contents

### Status line

| Entry | What it is |
|---|---|
| [`statusline-context-gauge/`](statusline-context-gauge/) | Live context-window fill gauge for the Claude Code status line (the desktop app's filling-circle, in the terminal). Color warns on *absolute* token load, not just % of window. |

### tmux gadgets

| Entry | What it is |
|---|---|
| [`tmux-attention-bell/`](tmux-attention-bell/) | Flags the tmux window red and rings a bell when Claude finishes a turn or needs permission; clears when you reply. Bell cascades through nested tmux/SSH so a remote agent can light up your local status bar. |
| [`clear-claude/`](clear-claude/) | Fire a real `/clear` (or any slash-command) at a tmux-hosted Claude session from outside the conversation via `tmux send-keys` — for the iOS app, phone shortcuts, or plain-language "clear it". |

## Contributing

Got a small, portable Claude Code trick? See [CONTRIBUTING.md](CONTRIBUTING.md) —
one self-contained gadget per directory, a README that covers what / how / *why*,
and a row in the Contents above.

## License

[BSD 3-Clause](LICENSE) © 2026 Erik Greenwald. Take what's useful.
