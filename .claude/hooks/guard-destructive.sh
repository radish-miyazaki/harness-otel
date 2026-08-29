#!/usr/bin/env bash
# データを消す・履歴を書き換えるコマンドは、人が確認してから実行する。
set -euo pipefail

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

pattern='terraform +destroy|docker +volume +(rm|prune)|docker +system +prune|git +push +[^|]*(--force|-f)\b|rm +-rf +/'
if echo "$cmd" | grep -Eq "$pattern"; then
  jq -n --arg c "$cmd" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: ("収集済みデータや履歴を失う可能性があります: " + $c)
    }
  }'
fi
exit 0
