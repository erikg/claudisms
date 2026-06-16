# clear-claude

Fire a **real `/clear`** at a tmux-hosted Claude Code session from *outside* the
conversation — by injecting the keystrokes into the CLI's pane with
`tmux send-keys`. Lets you clear context from places where you can't actually
type a slash-command: the iOS app (where slash input is flaky), an SSH-based
phone shortcut, a cron job, or Claude's own Bash tool when you ask it in plain
language ("clear it").

```sh
clear-claude            # /clear the Claude pane in window 0 of the current/first session
clear-claude -n         # dry run: print the resolved target, send nothing
clear-claude 2          # target window index 2 instead
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

- **Session resolution** — inside tmux (`$TMUX` set, e.g. Claude's Bash tool or
  your own pane) it targets the **current** session, so it Just Works without
  arguments. Outside tmux (e.g. an SSH one-liner from a phone) there's no
  "current" session, so it falls back to the **first** listed one — the common
  single-session case. Multi-session users pass the window explicitly.
- **`WINDOW_INDEX` default `0`, pane `.0`** — the overwhelmingly common spot for
  the one long-lived Claude pane. If yours lives elsewhere, pass the index; the
  pane is assumed to be `.0` of that window. *(This is the one assumption to
  check on a fresh setup — `clear-claude -n` prints the resolved target and the
  command running there so you can confirm before sending.)*
- **`-n` dry-run** — because send-keys is irreversible (you can't un-clear), the
  dry run lets you verify the target — and that `pane_current_command` actually
  looks like a Claude process — before committing.
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
# → clear-claude DRY-RUN: would send /clear -> mysession:0.0 (running: node)
```

If the target or `running` command isn't what you expect, pass the right window
index. Only drop `-n` once the dry run points at the right pane.

## Requires

`bash` and `tmux`. The Claude session must be running inside tmux (that's the
whole delivery mechanism). No `jq`, nothing to build.
