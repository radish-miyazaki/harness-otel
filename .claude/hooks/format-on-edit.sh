#!/usr/bin/env bash
# 編集直後に整形して、フォーマット差分だけのコミットを作らせない。
set -uo pipefail

path=$(jq -r '.tool_input.file_path // empty')
[ -z "$path" ] || [ ! -f "$path" ] && exit 0

case "$path" in
  *.tf|*.tfvars) command -v terraform >/dev/null && terraform fmt "$path" >/dev/null ;;
  *.sh)          command -v shellcheck >/dev/null && shellcheck "$path" >&2 || true ;;
esac
exit 0
