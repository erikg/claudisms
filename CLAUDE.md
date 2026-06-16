# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`claudisms` is a collection of small, portable Claude Code tooling gadgets — the
kind of thing that otherwise lives buried in `~/.claude/` and gets lost on the
next machine. There is no build, no test suite, and no package manifest; it is a
grab-bag of self-contained scripts plus prose.

## Structure convention

Each gadget lives in its own subdirectory containing the script(s) **and** a
`README.md`. The top-level `README.md` groups gadgets into logical sections (e.g.
"Status line", "tmux gadgets"), one table per section — when you add a gadget,
add its row under the section it fits, or start a new section if none fits. Each
gadget's README is expected to explain three things: what it does, how to wire it
in, and *why* the defaults are what they are (the "why" is treated as
load-bearing, not optional).

## Conventions that matter here

- These scripts integrate with Claude Code's own extension surfaces (status line,
  hooks, etc.). When touching one, the source of truth for the integration
  contract is the Claude Code docs linked in the gadget's README — read it rather
  than guessing field names. For `statusline-context-gauge`, the contract is the
  JSON object piped on stdin to a `statusLine` command, whose stdout *becomes*
  the status line; the relevant fields are documented in its README.
- Design intent is opinionated and documented. Example: the context gauge colors
  by **absolute** input-token load (red at 200k), not percentage of the window,
  because on a 1M window 80% is useless as a "getting heavy" warning. Preserve
  this kind of reasoning when editing — if you change a threshold or behavior,
  update the README's rationale to match.

## Testing a gadget

There is no harness; gadgets are exercised by feeding them their real input.
The pattern is a "Smoke test" section in each README — e.g. pipe a sample JSON
object into `statusline.sh` and eyeball the output:

```sh
printf '%s' '{"model":{"display_name":"Opus 4.8"},"workspace":{"current_dir":"/home/erik/projects"},"context_window":{"used_percentage":29,"total_input_tokens":292600,"context_window_size":1000000}}' \
  | ./statusline-context-gauge/statusline.sh; echo
```

Shell gadgets here target bash and depend on `jq`.
