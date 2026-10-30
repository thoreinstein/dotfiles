#!/usr/bin/env bash
#
# Tests for git-bypass-guard: which Bash commands it denies and which it lets through.
#
# Usage: ./test_git_bypass_guard.sh   (needs jq and grep on PATH)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/git-bypass-guard"
FAILED=0

# verdict <command> prints "deny" or "allow".
verdict() {
  jq -n --arg c "$1" '{tool_input: {command: $c}}' | bash "$GUARD" | jq -r '.hookSpecificOutput.permissionDecision // "allow"' | grep . || echo allow
}

expect() {
  local want="$1" cmd="$2" got
  got="$(verdict "$cmd")"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: want $want, got $got: $cmd"
    FAILED=$((FAILED + 1))
  fi
}

for cmd in \
  'git commit --no-verify -m x' \
  'git commit -n -m x' \
  'git commit -anm x' \
  'git -C /tmp/r commit --no-verify' \
  'git -c core.hooksPath=/dev/null commit -m x' \
  'git config core.hooksPath /dev/null' \
  'SKIP=shellcheck git commit -m x' \
  'git add . && git commit --no-verify -m x' \
  'git commit --no-gpg-sign -m x' \
  'git -c commit.gpgsign=false commit -m x' \
  'git config commit.gpgsign false' \
  "bash -c 'git commit --no-verify'" \
  "bash -c 'git commit -n -m x'" \
  "bash -c 'git commit --no-gpg-sign'" \
  'git config --global core.hooksPath /dev/null' \
  'git config set core.hooksPath /dev/null' \
  'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null git commit -m x' \
  "GIT_CONFIG_PARAMETERS=\"'core.hooksPath=/dev/null'\" git commit -m x" \
  'HUSKY=0 git commit -m x' \
  'LEFTHOOK=0 git push' \
  'PRE_COMMIT_ALLOW_NO_CONFIG=1 git commit -m x' \
  'rm .git/hooks/pre-commit && git commit -m x' \
  'chmod -x .git/hooks/pre-commit' \
  'mv .git/hooks .git/hooks.bak' \
  'pre-commit uninstall' \
  'git -c gpg.program=/usr/bin/true commit -m x' \
  'git config gpg.program /usr/bin/true' \
  'git config --global gpg.program true'; do
  expect deny "$cmd"
done

for cmd in \
  'git status' \
  'git commit -m x' \
  'git commit -m "mention --no-verify in the message"' \
  "git commit -m 'drop commit.gpgsign=false from the docs'" \
  'git push -n' \
  'git status && ls -n' \
  'git config --get core.hooksPath' \
  'git config --get commit.gpgsign' \
  'SKIP=shellcheck git status' \
  'git config --global --get core.hooksPath' \
  'git config --unset core.hooksPath' \
  'git config --get gpg.program' \
  'git config gpg.program' \
  'HUSKY=0 npm install' \
  'ls .git/hooks' \
  'cat .git/hooks/pre-commit' \
  'pre-commit run --all-files' \
  'pre-commit install' \
  'ls -n' \
  'echo hello'; do
  expect allow "$cmd"
done

if ((FAILED > 0)); then
  echo "$FAILED failure(s)"
  exit 1
fi
echo "git-bypass-guard: ok"
