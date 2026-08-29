# 0007: ツールは mise、Git フックは prek、CI は GitHub Actions

- 状態: 採用
- 日付: 2026-08-29

## 状況

グローバル環境を汚さずに Terraform / lint 類を揃えたい。commit 前と CI で同じ検査を走らせたい。

## 判断

- `.mise.toml` にツールをパッチバージョンで固定。`mise run` のタスクで init / plan / apply / lint / smoke を提供
- Git フックは prek（pre-commit 互換で Python 不要）。`.pre-commit-config.yaml` に terraform fmt / validate / tflint、gitleaks、ryl（yamllint 互換の Rust 実装）、rumdl（Markdown）、shellcheck、actionlint、terraform-docs を並べる。ryl と rumdl は mise で入れた実行ファイルを `language: system` で呼ぶ
- CI は `jdx/mise-action` で同じツールを入れ、`prek run --all-files` と `terraform validate` を実行。Docker は使わない
- Claude Code のプロジェクトフック（`.claude/settings.json`）は 3 つ: 秘密ファイルへの書き込み拒否、破壊的コマンドの確認、編集後の `terraform fmt`

## 結果

- ローカルと CI で検査内容がずれない
- terraform-docs は `terraform/README.md` と `modules/*/README.md` のマーカー内に入力・出力表を書き込む。生成物なので rumdl の対象から外す
- rumdl は日本語文章が前提なので行長（MD013）を見ない。`docs/spec/` はリポジトリに含めないので対象外
- `check-yaml` と `ryl` は `.tftpl` を除外する。Terraform のディレクティブが混ざるので YAML として妥当ではない
