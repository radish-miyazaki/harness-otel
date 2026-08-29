#!/usr/bin/env bash
# config/ はホストマウントせず upload でコンテナに埋め込む（ADR 0003）。
# 編集しただけでは反映されず、気づくのはダッシュボードを開いた後になるので、その場で伝える。
set -uo pipefail

path=$(jq -r '.tool_input.file_path // empty')
[ -z "$path" ] && exit 0

case "$path" in
  */terraform/config/*)
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: "terraform/config/ の変更は upload でコンテナに埋め込まれる。反映にはコンテナを作り直す mise run apply が必要。Collector の scrub を触ったなら続けて mise run smoke まで回す"
      }
    }'
    ;;
esac
exit 0
