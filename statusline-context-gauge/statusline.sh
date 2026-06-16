#!/usr/bin/env bash
# statusline.sh — Claude Code status line: model · dir · context gauge
#
# Circle ◯◔◑◕● = true window fill (% of the context window).
# Color = absolute input-token load on a "lean is better" scale:
#         green < 100k · yellow 100k–200k · red >= 200k.
# Override the thresholds via ~/.claude/ctx-gauge.json (or a per-project
# <project>/.claude/ctx-gauge.json), or the CTX_GAUGE_RED / CTX_GAUGE_YELLOW env.
#
# Install: see README.md (add a statusLine key to ~/.claude/settings.json).
in=$(cat)

# One jq pass pulls every field. The read order below MUST match the emit
# order here — they're paired positionally, so keep them in sync if you edit.
{ IFS= read -r model
  IFS= read -r dir
  IFS= read -r proj
  IFS= read -r pct
  IFS= read -r inp
  IFS= read -r size
} < <(jq -r '
  .model.display_name // "?",
  .workspace.current_dir // .cwd // "",
  .workspace.project_dir // .workspace.current_dir // .cwd // "",
  .context_window.used_percentage // 0,
  .context_window.total_input_tokens // 0,
  .context_window.context_window_size // 200000
' <<<"$in")
dir=${dir##*/}; pct=${pct%.*}

# filling-circle gauge: ◯ ◔ ◑ ◕ ●  (fraction of the actual window)
if   (( pct < 10 )); then g=◯
elif (( pct < 35 )); then g=◔
elif (( pct < 60 )); then g=◑
elif (( pct < 85 )); then g=◕
else                      g=●; fi

# color by absolute input tokens. Thresholds resolve low → high precedence:
#   built-in  <  ~/.claude/ctx-gauge.json  <  <project>/.claude/ctx-gauge.json  <  env
# Config file shape: {"red":200000,"yellow":100000} — either key optional.
red=200000 yellow=100000           # built-in defaults
load_cfg() {                       # pull .red/.yellow from a json file if it exists
  [ -f "$1" ] || return 0
  local r y
  { IFS= read -r r; IFS= read -r y; } < <(jq -r '.red // "", .yellow // ""' "$1" 2>/dev/null)
  [ -n "$r" ] && red=$r
  [ -n "$y" ] && yellow=$y
}
load_cfg "$HOME/.claude/ctx-gauge.json"
[ -n "$proj" ] && load_cfg "$proj/.claude/ctx-gauge.json"
red=${CTX_GAUGE_RED:-$red}
yellow=${CTX_GAUGE_YELLOW:-$yellow}

if   (( inp >= red ));    then c='\033[31m'   # red:    over the comfort line
elif (( inp >= yellow )); then c='\033[33m'   # yellow: getting heavy
else                          c='\033[32m'; fi # green: lean

printf '%s · %s · %b%s %d%% (%dk/%dk)\033[0m' \
  "$model" "$dir" "$c" "$g" "$pct" "$((inp/1000))" "$((size/1000))"
