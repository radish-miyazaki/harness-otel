#!/usr/bin/env bash
# ADR の定型部分（採番・テンプレ展開・目次への追記・CLAUDE.md の次番号）だけを機械で済ませる。
# 本文は書けないので、出力されたパスを開いて 状況 / 判断 / 結果 を埋める。
set -euo pipefail

usage() {
  echo "usage: $0 <english-kebab-case-slug> <日本語の題名>" >&2
  exit 1
}
[ $# -eq 2 ] || usage

slug=$1
title=$2
echo "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || usage

root=$(git rev-parse --show-toplevel)
adr_dir="${root}/docs/adr"

max=$(find "$adr_dir" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -exec basename {} \; |
  cut -d- -f1 | sort -n | tail -1)
num=$(printf '%04d' $((10#${max:-0000} + 1)))
next=$(printf '%04d' $((10#$num + 1)))

file="${adr_dir}/${num}-${slug}.md"
[ -e "$file" ] && {
  echo "既に存在します: ${file}" >&2
  exit 1
}

# 途中で落ちると、番号だけ消費した書きかけが残って次の採番がずれる。最後まで通らなければ消す
finished=0
trap '[ "$finished" = 1 ] || rm -f "$file"' EXIT

# 題名に sed のメタ文字が入っても壊れないよう awk の変数で渡す
awk -v h="# ${num}: ${title}" -v d="- 日付: $(date +%Y-%m-%d)" '
  NR == 1                     { print h; next }
  /^- 日付: YYYY-MM-DD$/      { print d; next }
                              { print }
' "${adr_dir}/template.md" >"$file"

# macOS の mktemp は引数なしだと TMPDIR を見ないのでテンプレートを渡す
tmp=$(mktemp "${TMPDIR:-/tmp}/new-adr.XXXXXX")

# 目次は表の最終行のあとに足す。表のあとに文章が増えても壊れないようにする
awk -v row="| [${num}](${num}-${slug}.md) | ${title} | 採用 |" '
  { lines[NR] = $0 }
  /^\| \[[0-9][0-9][0-9][0-9]\]/ { last = NR }
  END {
    for (i = 1; i <= NR; i++) {
      print lines[i]
      if (i == last) print row
    }
  }
' "${adr_dir}/README.md" >"$tmp"
mv "$tmp" "${adr_dir}/README.md"

# CLAUDE.md の「次は NNNN」を進める。ここがずれると採番を手で数える羽目になる
if grep -q '（次は [0-9]\{4\}）' "${root}/CLAUDE.md"; then
  tmp=$(mktemp "${TMPDIR:-/tmp}/new-adr.XXXXXX")
  sed "s/（次は [0-9]\{4\}）/（次は ${next}）/" "${root}/CLAUDE.md" >"$tmp"
  mv "$tmp" "${root}/CLAUDE.md"
else
  echo "警告: CLAUDE.md に「（次は NNNN）」が見つからないので更新していない" >&2
fi

finished=1
echo "$file"
