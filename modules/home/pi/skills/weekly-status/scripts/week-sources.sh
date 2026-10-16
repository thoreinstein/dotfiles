#!/usr/bin/env bash
# Collect one week of raw material for a status update.
#
# Prints markdown with three sections: pi sessions, engram observations, and
# vault notes, all limited to [start, end] in local time. Read-only: it never
# writes to pi, engram, or the vault.
#
# Usage: week-sources.sh [--start YYYY-MM-DD] [--end YYYY-MM-DD]
# Default range is Monday of the current week through today.
#
# macOS only: BSD date/find/stat are called by absolute path because GNU
# coreutils may shadow them on PATH.
# shellcheck disable=SC2016 # $vars in single quotes are jq's, not the shell's
set -euo pipefail

SESSIONS="$HOME/.pi/agent/sessions"
VAULT="$HOME/Documents/second_brain"

start=$(/bin/date -v-"$(($(/bin/date +%u) - 1))"d +%F)
end=$(/bin/date +%F)
while [[ $# -gt 0 ]]; do
  case $1 in
    --start) start=$2; shift 2 ;;
    --end) end=$2; shift 2 ;;
    *) echo "usage: $0 [--start YYYY-MM-DD] [--end YYYY-MM-DD]" >&2; exit 2 ;;
  esac
done
end_next=$(/bin/date -j -v+1d -f %F "$end" +%F)

# Shared jq helpers. pi writes ISO timestamps with Z; engram writes UTC
# "YYYY-MM-DD HH:MM:SS". Both become local dates.
JQ_LIB='
def epoch: sub("\\.[0-9]+"; "") | sub(" "; "T") | (if endswith("Z") then . else . + "Z" end) | fromdateiso8601;
def day: epoch | strflocaltime("%Y-%m-%d");
def clip($n): gsub("\\s+"; " ") | sub("^ "; "") | sub(" $"; "") | if length <= $n then . else .[:$n - 1] + "…" end;
def txt: .content | if type == "string" then . else map(select(.type == "text") | .text // "") | join("\n") end;
'

echo "# Week $start to $end"
echo

echo "## pi sessions"
echo
# Cheap pre-filter: a session last written before the range can't be in it.
files=()
while IFS= read -r -d '' f; do files+=("$f"); done \
  < <(/usr/bin/find "$SESSIONS" -name '*.jsonl' -newermt "$start" -print0 2>/dev/null)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "(none)"
else
  jq -nRr --arg start "$start" --arg end "$end" --arg home "$HOME" "$JQ_LIB"'
    reduce (inputs | (fromjson? // empty) as $d | {f: input_filename, d: $d}) as $x ({};
      if $x.d.type == "session" then .[$x.f].h = $x.d
      elif $x.d.type == "message" and $x.d.message.role == "user" then .[$x.f].u += [$x.d.message | txt]
      elif $x.d.type == "message" and $x.d.message.role == "assistant" then
        ($x.d.message | txt | sub("^\\s+"; "") | sub("\\s+$"; "")) as $t
        | if $t != "" then .[$x.f].r = $t else . end
      else . end)
    | [.[] | select(.h and (.u | length > 0))
        | {day: (.h.timestamp | day), label: (.h.timestamp | epoch | strflocaltime("%a %m-%d")), cwd: (.h.cwd // ""), u, r}
        | select(.day >= $start and .day <= $end)]
    | sort_by(.day, .cwd)
    | if length == 0 then "(none)" else .[]
      | ([.cwd | match("\\b[A-Z][A-Z0-9]+-[0-9]+\\b"; "g").string] | unique) as $tickets
      | (if (.cwd | startswith($home)) then "~" + .cwd[($home | length):] else .cwd end) as $cwd
      | ["### \(.label) · \($cwd)" + (if $tickets != [] then " · " + ($tickets | join(", ")) else "" end),
         "- turns: \(.u | length)"]
        + [.u[:2][] | "- asked: " + clip(300)]
        + (if .r then ["- last reply: " + (.r | clip(400))] else [] end)
        + [""]
      | join("\n")
      end
  ' "${files[@]}"
fi

echo "## engram observations"
echo
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if engram export --all "$tmp/export.json" >/dev/null 2>&1; then
  jq -r --arg start "$start" --arg end "$end" "$JQ_LIB"'
    [.observations[] | .day = (.created_at | day) | select(.day >= $start and .day <= $end)]
    | if length == 0 then "(none)" else
      group_by(.project // "")[]
      | sort_by(.created_at)
      | "", "### \(.[0].project)",
        (.[] | "- \(.created_at | epoch | strflocaltime("%a")) [\(.type)] \(.title) — \(.content // "" | clip(500))")
      end
  ' "$tmp/export.json"
else
  echo "(engram export failed; fall back to mem_search)"
fi
echo

echo "## vault notes"
echo
echo "Daily notes (summaries of each day's engram activity, grouped by project):"
found=0
d=$start
while [[ $d < "$end_next" ]]; do
  p="$VAULT/Daily/$(/bin/date -j -f %F "$d" +%Y/%m/%F).md"
  if [[ -f $p ]]; then echo "- $p"; found=1; fi
  d=$(/bin/date -j -v+1d -f %F "$d" +%F)
done
[[ $found -eq 1 ]] || echo "- (none)"

echo
echo "Project notes in working/ modified this week:"
touched=$(/usr/bin/find "$VAULT/working" -name '*.md' -newermt "$start" ! -newermt "$end_next" \
  -exec /usr/bin/stat -f '%m %Sm %N' -t %a {} + 2>/dev/null | sort -n | cut -d' ' -f2- | sed 's/^/- /')
echo "${touched:-- (none)}"
echo
