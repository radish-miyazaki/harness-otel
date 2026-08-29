# 0007: ツールは mise、Git フックは prek、CI は GitHub Actions

- 状態: 採用
- 日付: 2026-08-29

## 状況

グローバル環境を汚さずに Terraform / lint 類を揃えたい。commit 前と CI で同じ検査を走らせたい。

## 判断

- `.mise.toml` にツールをパッチバージョンで固定。`mise run` のタスクで init / plan / apply / lint / smoke を提供
- Git フックは prek（Python 不要）。設定に terraform fmt / validate / tflint、gitleaks、ryl（yamllint の Rust 実装）、rumdl（Markdown）、shellcheck、actionlint、terraform-docs を並べる。mise で入れた実行ファイルは `language: system` で直接呼ぶ。設定ファイルは当初 `.pre-commit-config.yaml` だったが、[0013](0013-native-configs-for-prek-and-ryl.md) で `prek.toml` に移した
- CI は `jdx/mise-action` で同じツールを入れ、`prek run --all-files` と `terraform validate` を実行。Docker は使わない
- Claude Code のプロジェクトフック（`.claude/settings.json`）は 3 つ: 秘密ファイルへの書き込み拒否、破壊的コマンドの確認、編集後の `terraform fmt`

## 結果

- ローカルと CI で検査内容がずれない
- terraform-docs は `terraform/README.md` と `modules/*/README.md` のマーカー内に入力・出力表を書き込む。生成物なので rumdl の対象から外す
- rumdl は日本語文章が前提なので行長（MD013）を見ない。`docs/spec/` はリポジトリに含めないので対象外
- `.tftpl` は Terraform のディレクティブが混ざるので YAML として妥当ではない。`check-yaml` のフックと `.ryl.toml` の `ignore` で除外する
