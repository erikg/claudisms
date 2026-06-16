# clear-claude

Fire a **real `/clear`** at a tmux-hosted Claude Code session from *outside* the
conversation — by injecting the keystrokes into the CLI's pane with
`tmux send-keys`. Lets you clear context from places where you can't actually
type a slash-command: the iOS app (where slash input is flaky), an SSH-based
phone shortcut, a cron job, or Claude's own Bash tool when you ask it in plain
language ("clear it").

```sh
clear-claude            # /clear the Claude pane (auto-detected when run inside it)
clear-claude -n         # dry run: print the resolved target + a Claude check, send nothing
clear-claude 2          # target window index 2 instead (pane .0)
clear-claude -f 2       # send even if window 2 doesn't look like a Claude pane
```

## The trick

A slash-command like `/clear` is only special when the **CLI itself** reads it
off its prompt — there's no API or signal for it. So to trigger one
programmatically you have to *type* it where the CLI is listening. tmux can do
exactly that: `tmux send-keys -t <pane> '/clear' Enter` pushes the characters
into the target pane's pty as if you'd typed them.

The keys **queue in the pty** and are consumed when the CLI next returns to its
prompt — i.e. right after the current turn ends. That's why it's safe to invoke
mid-turn: Claude can run this from its own Bash tool, finish responding, and the
`/clear` lands the instant it's back at the prompt. (It also means nothing
happens until there *is* a prompt — if the pane is sitting in a permission
dialog, the keys wait.)

Swap `'/clear'` for any other slash-command and the same mechanism drives
`/compact`, `/model`, etc. `/clear` is just the one worth a dedicated alias.

## Why these defaults

- **Target resolution** — three cases, in order:
  - **`WINDOW_INDEX` given** → `<current-or-first session>:<WINDOW_INDEX>.0`. The
    explicit override for the external/SSH case; pane `.0` of that window is
    assumed.
  - **else `$TMUX_PANE` set** (run from inside the Claude pane — e.g. its own Bash
    tool, or your own pane) → target **that exact pane**, deriving session,
    **window** *and* pane from the pane id. This is the key default: `$TMUX_PANE`
    pins the *whole* coordinate, so "clear it" lands on the right Claude no matter
    which window or pane it occupies — not just window 0. (Earlier this hardcoded
    window `0`; it only worked because Claude usually sits there.)
  - **else** (external, no arg) → `<first session>:0.0` — the common
    single-session, one-Claude-pane case.
- **`-n` dry-run** — because send-keys is irreversible (you can't un-clear), the
  dry run prints the resolved target *and* whether it looks like Claude, so you
  can confirm before committing.
- **Is-this-Claude guard (`-f` to override)** — before sending, the target's
  `pane_current_command` is checked: Claude Code sets its process title to its
  version (e.g. `2.1.178`), so a version string — or `node`/`claude` on older
  builds — means Claude is there. Anything else (a bare shell, `vim`, `ssh`) is
  almost certainly the wrong pane, so the send is **refused** unless you pass
  `-f`/`--force`. This turns the old "eyeball the dry-run" advice into an actual
  safety interlock, which matters most for the unattended paths (cron, SSH
  shortcut) where nobody reads the dry run.
- **`set -eu`** — fail loud on an unresolved session or missing pane rather than
  silently sending `/clear` into the wrong window.

## Install

```sh
cp clear-claude ~/bin/clear-claude     # or anywhere on $PATH
chmod +x ~/bin/clear-claude
```

Optional — wire the plain-language trigger so "clear it" works from the app.
Add to your `~/.claude/CLAUDE.md` so Claude knows to run it via Bash:

```md
When I say "clear it" / "clear the conversation" in plain language, run
`~/bin/clear-claude` via Bash. It injects a real /clear into the tmux-hosted
Claude pane. Safe to invoke mid-turn — the keys queue and fire at the next prompt.
```

For a phone shortcut, point an SSH action at `clear-claude` (no args needed if
you run a single tmux session).

## Smoke test

```sh
clear-claude -n
# → clear-claude DRY-RUN: would send /clear -> 0:0.0 (running: 2.1.178 -- looks like Claude)
```

`running` is the target's `pane_current_command`; current Claude Code reports its
**version** there (older builds showed `node`). If the target or the Claude
verdict isn't what you expect, pass the right window index. Only drop `-n` once
the dry run points at the right pane.

## Requires

`bash` and `tmux`. The Claude session must be running inside tmux (that's the
whole delivery mechanism). No `jq`, nothing to build.
