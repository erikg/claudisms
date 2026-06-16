#!/usr/bin/env bash
# statusline.sh — Claude Code status line: model · dir · context gauge
#
# Circle ◯◔◑◕● = true window fill (% of the context window).
# Color = absolute input-token load on a "lean is better" scale:
#         green < 100k · yellow 100k–200k · red >= 200k.
# Tune the two numbers in the `inp >=` lines to taste.
#
# Install: see README.md (add a statusLine key to ~/.claude/settings.json).
in=$(cat)

model=$(jq -r '.model.display_name // "?"' <<<"$in")
dir=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$in"); dir=${dir##*/}
pct=$(jq -r '.context_window.used_percentage // 0' <<<"$in"); pct=${pct%.*}
inp=$(jq -r '.context_window.total_input_tokens // 0' <<<"$in")
size=$(jq -r '.context_window.context_window_size // 200000' <<<"$in")

# filling-circle gauge: ◯ ◔ ◑ ◕ ●  (fraction of the actual window)
if   (( pct < 10 )); then g=◯
elif (( pct < 35 )); then g=◔
elif (( pct < 60 )); then g=◑
elif (( pct < 85 )); then g=◕
else                      g=●; fi

# color by absolute input tokens — tune these two numbers to taste
if   (( inp >= 200000 )); then c='\033[31m'   # red:    over the comfort line
elif (( inp >= 100000 )); then c='\033[33m'   # yellow: getting heavy
else                          c='\033[32m'; fi # green:  lean

printf '%s · %s · %b%s %d%% (%dk/%dk)\033[0m' \
  "$model" "$dir" "$c" "$g" "$pct" "$((inp/1000))" "$((size/1000))"
