# INSTALL

Deterministic install/update recipe for every gadget in this repo — written so a
human *or* Claude Code can run it without exploring or guessing. **If you are
Claude and the user said "install these" (or similar): do exactly what is in this
file. Run the fenced `bash` blocks below in order; do not go hunting through the
gadget directories first.**

The per-gadget READMEs remain the source of truth for *what each gadget does and
why*. This file is only the *mechanics* of getting them onto a machine. Where the
two ever disagree about a command, the README wins — fix this file to match.

## Preconditions

1. **Clone the repo and run every command from its root.** All paths below are
   relative to the repo root (the directory holding this `INSTALL.md`).

   ```sh
   git clone https://github.com/erikg/claudisms.git
   cd claudisms
   ```

2. **Confirm you're at the root** before running anything else — the install
   blocks fail safe by checking for a sentinel:

   ```sh
   test -f INSTALL.md && test -d statusline-context-gauge \
     || { echo "Not in the claudisms repo root — cd there first."; }
   ```

3. **Dependencies**, by gadget:
   - `statusline-context-gauge` → `bash` + `jq`
   - `tmux-attention-bell` → `bash` + `tmux` (no `jq` for the gadget itself; the
     wiring step below uses `jq` to edit `settings.json`)
   - `clear-claude` → `bash` + `tmux`

   Install `jq` if missing: `brew install jq` (macOS) / `apt-get install jq`
   (Debian/Ubuntu).

## Install / update everything

These blocks are **idempotent** — re-running them is exactly how you *update* an
existing install (file copies overwrite, `settings.json` edits replace rather
than duplicate). To update after `git pull`, just run the same blocks again.

Run them in this order. Each is self-contained.

### 1. statusline-context-gauge

```sh
# Copy the script and register it as the statusLine command (idempotent).
cp statusline-context-gauge/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

[ -f ~/.claude/settings.json ] || printf '{}\n' > ~/.claude/settings.json
tmp=$(mktemp)
jq '.statusLine = {"type":"command","command":"~/.claude/statusline.sh"}' \
   ~/.claude/settings.json >"$tmp" && mv "$tmp" ~/.claude/settings.json
```

Shows on the next render — no restart. Smoke test:

```sh
printf '%s' '{"model":{"display_name":"Opus 4.8"},"workspace":{"current_dir":"/home/erik/projects"},"context_window":{"used_percentage":29,"total_input_tokens":292600,"context_window_size":1000000}}' \
  | ~/.claude/statusline.sh; echo
# → Opus 4.8 · projects · ◔ 29% (292k/1000k)
```

Optional color thresholds (see the gadget README for precedence rules):

```sh
printf '%s\n' '{ "red": 200000, "yellow": 100000 }' > ~/.claude/ctx-gauge.json
```

### 2. tmux-attention-bell

```sh
# Copy the two hook scripts and the tmux config.
mkdir -p ~/.claude/hooks
cp tmux-attention-bell/stop.sh tmux-attention-bell/prompt.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/stop.sh ~/.claude/hooks/prompt.sh
cp tmux-attention-bell/tmux.conf ~/.claude/tmux.conf

# Wire the hooks into settings.json. Idempotent: any prior entry pointing at
# our scripts is removed before re-adding, so re-running never duplicates hooks.
[ -f ~/.claude/settings.json ] || printf '{}\n' > ~/.claude/settings.json
h="$HOME/.claude/hooks"; tmp=$(mktemp)
jq --arg stop "$h/stop.sh" --arg prompt "$h/prompt.sh" '
    .hooks.Stop             = ((.hooks.Stop             // []) | map(select(.hooks[0].command != $stop)))   + [{"matcher":"","hooks":[{"type":"command","command":$stop}]}]
  | .hooks.Notification     = ((.hooks.Notification     // []) | map(select(.hooks[0].command != $stop)))   + [{"matcher":"","hooks":[{"type":"command","command":$stop}]}]
  | .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) | map(select(.hooks[0].command != $prompt))) + [{"matcher":"","hooks":[{"type":"command","command":$prompt}]}]
  ' ~/.claude/settings.json >"$tmp" && mv "$tmp" ~/.claude/settings.json

# Source the tmux config from ~/.tmux.conf (only if not already there) and reload.
grep -qF 'source-file ~/.claude/tmux.conf' ~/.tmux.conf 2>/dev/null \
  || echo 'source-file ~/.claude/tmux.conf' >> ~/.tmux.conf
tmux source-file ~/.tmux.conf 2>/dev/null || true   # no-op if not inside tmux
```

**One per-machine decision** (the only non-mechanical choice — see the gadget
README for the full emit-vs-eat reasoning):

- **The Mac/terminal you actually watch** should *eat* the bell so it doesn't
  beep on every turn:

  ```sh
  touch ~/.claude/tmux-eat-bell && tmux source-file ~/.tmux.conf
  ```

- **A remote/inner box where Claude runs** should *emit* (the default — leave the
  marker absent):

  ```sh
  rm -f ~/.claude/tmux-eat-bell && tmux source-file ~/.tmux.conf 2>/dev/null || true
  ```

Smoke test (from inside a tmux pane): `~/.claude/hooks/stop.sh` reddens the
window + rings the bell; `~/.claude/hooks/prompt.sh` clears it.

### 3. clear-claude

```sh
# Copy onto $PATH. ~/bin is assumed on PATH; adjust the destination if yours differs.
mkdir -p ~/bin
cp clear-claude/clear-claude ~/bin/clear-claude
chmod +x ~/bin/clear-claude
```

Optional — wire the plain-language "clear it" trigger so Claude runs it from the
app (idempotent; only appends the snippet once):

```sh
[ -f ~/.claude/CLAUDE.md ] && grep -qF '~/bin/clear-claude' ~/.claude/CLAUDE.md || cat >> ~/.claude/CLAUDE.md <<'EOF'

## Tooling — clear-claude
When I say "clear it" / "clear the conversation" in plain language, run
`~/bin/clear-claude` via Bash. It injects a real /clear into the tmux-hosted
Claude pane. Safe to invoke mid-turn — the keys queue and fire at the next prompt.
EOF
```

Smoke test (must be run inside the tmux-hosted Claude pane):

```sh
clear-claude -n
# → clear-claude DRY-RUN: would send /clear -> 0:0.0 (running: <ver> -- looks like Claude)
```

## After installing

- The status line and hooks are picked up by Claude Code on the next render /
  next turn — **no restart needed**.
- `tmux.conf` changes only take effect after `tmux source-file ~/.tmux.conf`
  (already run above), and must be applied on the **outermost** tmux too — the
  one whose status bar you watch — since that's where the bell cascade lands.

## Uninstall

```sh
# statusline
rm -f ~/.claude/statusline.sh ~/.claude/ctx-gauge.json
tmp=$(mktemp); jq 'del(.statusLine)' ~/.claude/settings.json >"$tmp" && mv "$tmp" ~/.claude/settings.json
# tmux-attention-bell
rm -f ~/.claude/hooks/stop.sh ~/.claude/hooks/prompt.sh ~/.claude/tmux.conf ~/.claude/tmux-eat-bell
h="$HOME/.claude/hooks"; tmp=$(mktemp)
jq --arg stop "$h/stop.sh" --arg prompt "$h/prompt.sh" '
    .hooks.Stop             = ((.hooks.Stop             // []) | map(select(.hooks[0].command != $stop)))
  | .hooks.Notification     = ((.hooks.Notification     // []) | map(select(.hooks[0].command != $stop)))
  | .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) | map(select(.hooks[0].command != $prompt)))
  ' ~/.claude/settings.json >"$tmp" && mv "$tmp" ~/.claude/settings.json
# (then remove the `source-file ~/.claude/tmux.conf` line from ~/.tmux.conf by hand)
# clear-claude
rm -f ~/bin/clear-claude
```
