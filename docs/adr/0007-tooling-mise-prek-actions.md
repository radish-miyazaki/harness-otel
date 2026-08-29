# 0007: ツールは mise、Git フックは prek、CI は GitHub Actions

- 状態: 採用
- 日付: 2026-08-29

## 状況

グローバル環境を汚さずに Terraform / lint 類を揃えたい。commit 前と CI で同じ検査を走らせたい。

## 判断

- `.mise.toml` にツールをパッチバージョンで固定。`mise run` のタスクで init / plan / apply / lint / smoke を提供
- Git フックは prek（pre-commit 互換で Python 不要）。`.pre-commit-config.yaml` に terraform fmt / validate / tflint、gitleaks、yamllint、shellcheck、actionlint を並べる
- CI は `jdx/mise-action` で同じツールを入れ、`prek run --all-files` と `terraform validate` を実行。Docker は使わない
- Claude Code のプロジェクトフック（`.claude/settings.json`）は 3 つ: 秘密ファイルへの書き込み拒否、破壊的コマンドの確認、編集後の `terraform fmt`

## 結果

- ローカルと CI で検査内容がずれない
- `check-yaml` と `yamllint` は `.tftpl` を除外する。Terraform のディレクティブが混ざるので YAML として妥当ではない
