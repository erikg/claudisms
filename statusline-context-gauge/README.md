# statusline-context-gauge

A live context-window fill gauge for the Claude Code **terminal** status line —
the equivalent of the desktop app's little filling circle, plus a color that
warns on *absolute* token load rather than just percentage of the window.

```
Opus 4.8 · projects · ◔ 29% (292k/1000k)
                      └─ red here: a quarter of the 1M window, but past 200k
```

## Why

Claude context is **append-only with no GC** — you can't redefine an earlier
turn or `makunbound` a stale instruction; it just accumulates and dilutes
attention. The only real remedy is `/clear` (reload the image from source —
your `.md` files / project notes). The failure mode is *waiting too long*:
by the time **autocompact** fires, you're already in the degraded, lossy zone.
Autocompact is the "you failed" marker, not a nudge.

This gauge is the **early** signal that should make autocompact unnecessary:
the line turns red well before any technical limit, prompting a `/clear` at the
next task boundary while context is still clean.

That's why the **color keys off absolute input tokens, not % of window**. On a
1M-token window, 80% is 800k — useless as a "getting heavy" warning. The
threshold that matters is *your* comfort line (here: red at 200k), independent
of the ceiling. The **circle** still shows true window fill, so you get both
readings at a glance: how full the window technically is (circle) and whether
you've crossed your own discipline line (color).

> *Footnote:* circle and color are two scalings of the **same** number —
> `used_percentage ≈ total_input_tokens / context_window_size`. The circle reads
> it *relative* to the window; the color reads it *absolute*. They're not
> independent measurements, but on a wide window they diverge usefully: at 200k
> on a 1M window you get a calm `◔` and an alarmed red at once.

## What the status line gives you

Claude Code runs your `statusLine` command and pipes a JSON object on stdin;
whatever the command prints to stdout **becomes** the status line (it replaces
the default info line, so render anything you want to keep). Relevant fields:

| Field | Meaning |
|---|---|
| `model.id`, `model.display_name` | active model |
| `workspace.current_dir`, `cwd` | working directory |
| `context_window.total_input_tokens` | input tokens currently in context |
| `context_window.total_output_tokens` | output tokens from last response |
| `context_window.context_window_size` | window max (e.g. 200000 or 1000000) |
| `context_window.used_percentage` | pre-computed % used (**input only**) |
| `context_window.remaining_percentage` | pre-computed % remaining |
| `exceeds_200k_tokens` | boolean past the 200k threshold |
| `transcript_path`, `session_id`, `version`, `cost.*`, `rate_limits`, `effort.level`, `thinking.enabled`, `vim.mode`, … | other session metadata |

No transcript parsing needed — `context_window.*` is live and pre-computed.
`used_percentage` is `null` before the first API call (the script defaults it
to 0 via `// 0`).

Behavior: updates after each assistant turn and after `/compact`, debounced
~300ms; runs locally (no token cost). Window size comes from the JSON, so the
gauge reads correctly whether you're on a 200k or 1M window — nothing hardcoded.

Source: <https://code.claude.com/docs/en/statusline.md>

## Install

```sh
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

(Edits to the *installed* copy show on the next render; if you'd rather hack on
the in-repo copy, `ln -s` it instead of `cp` so there's one file, not two.)

Add the `statusLine` key to `~/.claude/settings.json` (leaves everything else
intact):

```sh
# On a fresh machine ~/.claude/settings.json may not exist yet — jq errors on a
# missing file, so seed an empty object first (this is the "next machine" case).
[ -f ~/.claude/settings.json ] || printf '{}\n' > ~/.claude/settings.json
tmp=$(mktemp)
jq '.statusLine = {"type":"command","command":"~/.claude/statusline.sh"}' \
   ~/.claude/settings.json >"$tmp" && mv "$tmp" ~/.claude/settings.json
```

Or by hand:

```json
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
```

It shows on the next render — no restart needed.

**Requires** `bash` (≥3.2, so stock macOS is fine) and `jq`. The shebang runs it
under bash regardless of your login shell, so zsh-on-macOS is irrelevant. On
Windows it runs under WSL or Git Bash (point `command` at `bash …`) — not native
cmd/PowerShell — and the gauge glyphs need a UTF-8 terminal.

## Smoke test

```sh
printf '%s' '{"model":{"display_name":"Opus 4.8"},"workspace":{"current_dir":"/home/erik/projects"},"context_window":{"used_percentage":29,"total_input_tokens":292600,"context_window_size":1000000}}' \
  | ./statusline.sh; echo
# → Opus 4.8 · projects · ◔ 29% (292k/1000k)   (circle + counts in red)
```

## Tuning

- **Color thresholds** — the red / yellow token counts (default 200k / 100k).
  Lower them to nag earlier. Set them without touching the script via a small
  JSON file:

  ```json
  { "red": 200000, "yellow": 100000 }
  ```

  Either key is optional. Drop it at `~/.claude/ctx-gauge.json` for a global
  baseline, or at `<project>/.claude/ctx-gauge.json` to tighten the line for one
  noisy repo. Claude Code never hands your `settings.json` to the status line —
  it only pipes the session JSON — so the gauge reads this dedicated file itself,
  locating the project copy from the `workspace.project_dir` field in that JSON.

  Resolution runs lowest → highest precedence:

  | Source | Use |
  |---|---|
  | built-in `red=`/`yellow=` lines | the baked-in defaults |
  | `~/.claude/ctx-gauge.json` | your global comfort line |
  | `<project>/.claude/ctx-gauge.json` | per-repo override |
  | `CTX_GAUGE_RED` / `CTX_GAUGE_YELLOW` env | one-off, wins over all |

  A missing or malformed file is ignored silently and the next-lower source
  stands — the gauge never breaks over bad config.
- **Circle scale** — currently fills by % of the true window, so on a 1M window
  it mostly reads ◯/◔. To make the circle track your *own* scale instead (fill
  up by ~200k), threshold the gauge on `inp` rather than `pct`.
