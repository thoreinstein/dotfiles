#!/usr/bin/env bash
#
# Tests for claude-work-guard: which tool calls it denies and which it lets through.
#
# Usage: ./test_claude_work_guard.sh   (needs jq, grep and tr on PATH)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/claude-work-guard"
FAILED=0

# verdict <tool> <tool_input json> [cwd] prints "deny" or "allow".
verdict() {
  local out
  out="$(jq -n --arg t "$1" --argjson i "$2" --arg c "${3:-/Users/me/src/thoreinstein/dotfiles}" \
    '{tool_name: $t, tool_input: $i, cwd: $c}' | bash "$GUARD")"
  if [[ -z "$out" ]]; then echo allow; else jq -r '.hookSpecificOutput.permissionDecision' <<<"$out"; fi
}

expect() {
  local want="$1" got
  shift
  got="$(verdict "$@")"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: want $want, got $got: $*"
    FAILED=$((FAILED + 1))
  fi
}

E=mcp__plugin_engram_engram__
# engram: personal projects and unscoped calls pass
expect allow "${E}mem_search" '{"query":"x"}'
expect allow "${E}mem_search" '{"query":"x","project":"dotfiles"}'
expect allow mcp__engram__mem_save '{"title":"t","content":"c","project":"obsidian-mcp"}'
expect allow "${E}mem_context" '{}'
# engram: work projects, all_projects, id lookups and work directories do not
expect deny "${E}mem_search" '{"query":"x","project":"tf-env-saas-v2"}'
expect deny mcp__engram__mem_search '{"query":"x","project":"saas"}'
expect deny "${E}mem_search" '{"query":"x","all_projects":true}'
expect allow "${E}mem_search" '{"query":"x","all_projects":false}'
expect deny "${E}mem_get_observation" '{"id":7}'
expect deny "${E}mem_timeline" '{"observation_id":7}'
expect deny "${E}mem_save" '{"title":"t","content":"c","cwd":"/Users/me/src/forgecloud/saas/master"}'
expect deny "${E}mem_search" '{"query":"x"}' /Users/me/src/forgecloud/saas/master
expect deny "${E}mem_update" '{"id":1,"expected_project":"workbench-x"}'

# vault via obsidian-mcp
expect allow mcp__obsidian-mcp__obsidian_read_note '{"file_path":"Engineering/Patterns/Foo.md"}'
expect allow mcp__obsidian-mcp__obsidian_read_note '{"file_path":"working/finances/Money-Plan.md"}'
expect allow mcp__obsidian-mcp__obsidian_read_note '{"file_path":"engram/dotfiles/note.md"}'
expect allow mcp__obsidian-mcp__obsidian_search_notes '{"query":"x"}'
expect deny mcp__obsidian-mcp__obsidian_read_note '{"file_path":"working/fraas/fraas-36446.md"}'
expect deny mcp__obsidian-mcp__obsidian_read_note '{"file_path":"Working/FRAAS/x.md"}'
expect deny mcp__obsidian-mcp__obsidian_read_note '{"file_path":"engram/tf-env-saas-v2/x.md"}'
expect deny mcp__obsidian-mcp__obsidian_read_note '{"file_path":"engram/_sessions/foo.md"}'
expect deny mcp__obsidian-mcp__obsidian_list_notes '{"folder":"working"}'
expect deny mcp__obsidian-mcp__obsidian_list_notes '{"subfolder":"engram"}'
expect deny mcp__obsidian-mcp__obsidian_move_note '{"source_path":"Notes/a.md","dest_path":"working/inc/a.md"}'
expect deny mcp__obsidian-mcp__obsidian_read_note '{"file_path":"/Users/me/Documents/second_brain/working/self-review/log.md"}'

# built-in file tools
expect allow Read '{"file_path":"/Users/me/src/thoreinstein/dotfiles/README.md"}'
expect allow Read '{"file_path":"/Users/me/Documents/second_brain/working/health/x.md"}'
expect deny Read '{"file_path":"/Users/me/src/forgecloud/saas/master/README.md"}'
expect deny Edit '{"file_path":"/Users/me/Documents/second_brain/working/tf-env-saas-v2/onboarding-audit.md"}'
expect deny Grep '{"pattern":"x","path":"/Users/me/Documents/second_brain/engram/saas"}'
expect deny Glob '{"pattern":"**/*.tf","path":"/Users/me/src/forgecloud/tf-env-saas-v2/main"}'

# Bash
expect allow Bash '{"command":"git status"}'
expect allow Bash '{"command":"cat ~/Documents/second_brain/working/obsidian-mcp/plan.md"}'
expect deny Bash '{"command":"cd ~/src/forgecloud/saas/master && ls"}'
expect deny Bash '{"command":"cat ~/Documents/second_brain/working/fraas/fraas-36446.md"}'
expect deny Bash '{"command":"ls /Users/me/Documents/second_brain/engram/tf-env-images"}'

if ((FAILED > 0)); then
  echo "$FAILED failure(s)"
  exit 1
fi
echo "claude-work-guard: ok"
