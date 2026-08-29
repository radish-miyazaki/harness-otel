#!/usr/bin/env bash
# ADR の番号は連番で、欠番も再利用もしない。次の番号は手で数える限りずれるので、
# 書いた直後にファイル名・採番・目次への追記を突き合わせる。
set -uo pipefail

path=$(jq -r '.tool_input.file_path // empty')
[ -z "$path" ] && exit 0

case "$path" in
  */docs/adr/*.md) ;;
  *) exit 0 ;;
esac

adr_dir=$(dirname "$path")
name=$(basename "$path")
case "$name" in
  README.md | template.md) exit 0 ;;
esac

if ! echo "$name" | grep -Eq '^[0-9]{4}-[a-z0-9]+(-[a-z0-9]+)*\.md$'; then
  echo "ADR のファイル名は NNNN-english-kebab-case.md です: ${name}" >&2
  exit 2
fi

numbers() {
  find "$adr_dir" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' ! -name "$name" -exec basename {} \; |
    cut -d- -f1 | sort -n
}

num=${name%%-*}
if numbers | grep -qx "$num"; then
  echo "ADR 番号 ${num} は既に使われています。番号は再利用しません" >&2
  exit 2
fi

max=$(numbers | tail -1)
expected=$(printf '%04d' $((10#${max:-0000} + 1)))
if [ "$num" != "$expected" ]; then
  echo "ADR 番号は連番です。${expected} を使ってください（${num} で作成されています）" >&2
  exit 2
fi

if ! grep -q "(${name})" "${adr_dir}/README.md"; then
  jq -n --arg n "$name" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("docs/adr/README.md の表に " + $n + " の行がまだない。題名と状態を 1 行足し、CLAUDE.md の「次は NNNN」も進めること")
    }
  }'
fi
exit 0
