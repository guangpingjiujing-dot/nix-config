#!/usr/bin/env bash
input=$(cat)

format_reset() {
  local ts="$1" now diff
  now=$(date +%s)
  diff=$(( ts - now ))
  if   [ "$diff" -le 0 ];     then echo "now"
  elif [ "$diff" -lt 3600 ];  then echo "$(( diff / 60 ))m"
  elif [ "$diff" -lt 86400 ]; then echo "$(( diff / 3600 ))h$(( (diff % 3600) / 60 ))m"
  else                              echo "$(( diff / 86400 ))d$(( (diff % 86400) / 3600 ))h"
  fi
}

# Line 1: model, context window, rate limits with reset times
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "claude"')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage | select(. != null) | (round | tostring) + "%"')

five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage | select(. != null) | round | tostring')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at | select(. != null)')
seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage | select(. != null) | round | tostring')
seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at | select(. != null)')

line1="$model"
[ -n "$ctx" ] && line1="$line1 | ctx:$ctx"

if [ -n "$five_h_pct" ]; then
  entry="5h:${five_h_pct}%"
  [ -n "$five_h_reset" ] && entry="${entry}($(format_reset "$five_h_reset"))"
  line1="$line1 | $entry"
fi

if [ -n "$seven_d_pct" ]; then
  entry="7d:${seven_d_pct}%"
  [ -n "$seven_d_reset" ] && entry="${entry}($(format_reset "$seven_d_reset"))"
  line1="$line1 | $entry"
fi

# Line 2: git status in cwd
cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  git_status=$(git -C "$cwd" status --porcelain 2>/dev/null)

  staged=$(echo "$git_status"   | grep -E '^[^ ?]'  | wc -l | tr -d '[:space:]')
  modified=$(echo "$git_status" | grep -E '^.[^ ?]' | grep -v '^\?\?' | wc -l | tr -d '[:space:]')
  untracked=$(echo "$git_status" | grep -E '^\?\?'   | wc -l | tr -d '[:space:]')

  line2="$branch"
  [ "$staged" -gt 0 ]    && line2="$line2 S:$staged"
  [ "$modified" -gt 0 ]  && line2="$line2 M:$modified"
  [ "$untracked" -gt 0 ] && line2="$line2 ?:$untracked"
  if [ "$staged" -eq 0 ] && [ "$modified" -eq 0 ] && [ "$untracked" -eq 0 ]; then
    line2="$line2 clean"
  fi

  echo "$line1"
  echo "$line2"
else
  echo "$line1"
fi
