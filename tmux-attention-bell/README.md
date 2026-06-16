# tmux-attention-bell

Flags the tmux window **red** and rings a **bell** the moment Claude Code wants
you — when it finishes a turn or stops to ask permission — and clears the flag
the instant you reply. The point is to let you walk away from a long-running
agent and get pulled back exactly when there's something to do, even across
nested tmux sessions and SSH hops.

```
 0:edit  1:build  2:claude*    ← normal
 0:edit  1:build  2:claude*    ← Claude stops → window 2 goes red + bell
```

## How it works

Three pieces, two hooks and one tmux config:

| File | Wires to | Does |
|---|---|---|
| `stop.sh` | `Stop` + `Notification` hooks | paints the current window's status red, then emits a bell (`\a`) |
| `prompt.sh` | `UserPromptSubmit` hook | resets the window status back to default |
| `tmux.conf` | sourced from `~/.tmux.conf` | makes tmux *react* to bells from background windows |

The flow: Claude **stops** (turn done) or raises a **notification** (needs
permission) → `stop.sh` runs → your window turns red and a bell fires. You glance
over, see red, act. When you **submit** your next prompt → `prompt.sh` runs →
red clears. The window is red exactly during the interval where the ball is in
your court.

## Why a bell *and* a red window — they cover different distances

This looks redundant; it isn't. They travel different distances:

- **The red window-status** (`set-window-option`) talks straight to the tmux
  server the pane lives in. It's the at-a-glance local cue — but it only colors
  *that* tmux's status bar. It does not escape the session it runs in.
- **The bell** (`printf '\a'`) is a byte on the terminal stream. It rides the
  pane's output *upward* — through an outer tmux, through SSH, through another
  tmux on your laptop — until something chooses to notice it. That's the part
  that survives nesting. `stop.sh` fires both so you're covered whether you're
  looking at the local session or three layers up a remote stack.

`tmux.conf` is the "something that notices" at the top of the stack:

| Setting | Why |
|---|---|
| `monitor-bell on` | watch for bells in **background** windows at all (off by default) |
| `bell-action other` | alert only for bells in windows *other* than the focused one — don't pester you about the window you're already staring at |
| `visual-bell off` | we want the window-flag reaction, not a whole-screen flash |
| `window-status-bell-style 'bg=red,fg=white'` | so a bell from a nested Claude paints the outer window red too — the local red cue *cascades* all the way up |

Net effect: a Claude on a box two SSH hops away, running inside its own tmux,
can turn a window red on your laptop's status bar. That's the whole trick.

## Why these specific hook events

- **`Stop`** — Claude finished its turn. Your move. Red.
- **`Notification`** — Claude is blocked on you (a permission prompt, usually).
  Same "your move" semantics, so it shares `stop.sh`.
- **`UserPromptSubmit`** — the moment you re-engage. Submitting *is* the
  acknowledgement, so that's where the reset belongs (not on some timer, not on
  the next assistant message — the alert should persist until **you** act).

## Install

```sh
mkdir -p ~/.claude/hooks
cp stop.sh prompt.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/stop.sh ~/.claude/hooks/prompt.sh
cp tmux.conf ~/.claude/tmux.conf
```

Wire the hooks into `~/.claude/settings.json` (merges into any existing `hooks`):

```sh
[ -f ~/.claude/settings.json ] || printf '{}\n' > ~/.claude/settings.json
tmp=$(mktemp)
jq '.hooks.Stop              += [{"matcher":"","hooks":[{"type":"command","command":"/home/erik/.claude/hooks/stop.sh"}]}]
  | .hooks.Notification      += [{"matcher":"","hooks":[{"type":"command","command":"/home/erik/.claude/hooks/stop.sh"}]}]
  | .hooks.UserPromptSubmit  += [{"matcher":"","hooks":[{"type":"command","command":"/home/erik/.claude/hooks/prompt.sh"}]}]' \
  ~/.claude/settings.json >"$tmp" && mv "$tmp" ~/.claude/settings.json
```

(Hook commands need an absolute path — adjust `/home/erik` to your `$HOME`.)

Source the tmux config and reload — do this in the **outermost** tmux too (the
one whose status bar you actually watch), since that's where the cascade lands:

```sh
echo 'source-file ~/.claude/tmux.conf' >> ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

## Smoke test

From inside a tmux pane:

```sh
./stop.sh    # window goes red, terminal bell fires
./prompt.sh  # window returns to default
```

Switch to a *different* window first, then run `./stop.sh` in the original — the
background window should light up, confirming `monitor-bell` / `bell-action
other` are live. If nothing reddens, check that `$TMUX_PANE` is set (you're
actually inside tmux) and that `~/.tmux.conf` sources the config.

## Notes

- Pure `tmux` + `bash` — no `jq`, nothing to compile. The hooks no-op cleanly
  outside tmux (`$TMUX_PANE` unset), so they're safe to leave wired even when
  you run Claude in a plain terminal — you just lose the red, keeping the bell.
- `stop.sh` targets `-t "$TMUX_PANE"`; tmux resolves a pane id to its window, so
  the right window reddens even with multiple panes.
