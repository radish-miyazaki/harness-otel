#!/usr/bin/env bash
# 公開リポジトリなので、秘密情報を持ちうるファイルへの書き込みはエージェントに許可しない。
set -euo pipefail

path=$(jq -r '.tool_input.file_path // empty')
[ -z "$path" ] && exit 0

case "$(basename "$path")" in
  .env|.env.*|*.tfvars|*.tfstate|*.tfstate.*|*.pem|*.key|credentials*.json)
    case "$path" in *.example) exit 0 ;; esac
    jq -n --arg p "$path" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("秘密情報を含みうるファイルです: " + $p + "。値は環境変数か *.example で扱ってください")
      }
    }'
    ;;
esac
exit 0
