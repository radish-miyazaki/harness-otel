# 0013: prek と ryl は互換形式をやめてネイティブ設定に寄せる

- 状態: 採用
- 日付: 2026-08-29

## 状況

[0007](0007-tooling-mise-prek-actions.md) では prek に `.pre-commit-config.yaml` を、ryl に `.yamllint.yaml` を読ませていた。
pre-commit と yamllint に戻る予定はないので、互換のために払っているコストだけが残っている。

- `.mise.toml` の `[tools]` と `.pre-commit-config.yaml` の `rev` で、gitleaks・shellcheck・actionlint・zizmor の
  バージョンを二重に固定している。片方だけ上げても誰も気づかない
- `pre-commit/pre-commit-hooks` の 6 フックは prek に同梱の実装があるのに、リモートを clone して使っている
- ryl の呼び出しに `-c .yamllint.yaml` が要る

## 判断

`prek.toml`（prek 0.5.0）と `.ryl.toml`（ryl 0.21.0）に移す。変換は `prek util yaml-to-toml` と
`ryl --migrate-configs` で機械的にできる。

| フック | 移行前 | 移行後 |
| --- | --- | --- |
| end-of-file-fixer ほか 6 つ | `pre-commit/pre-commit-hooks` rev v5.0.0 | `repo = "builtin"`（prek 同梱。rev なし） |
| gitleaks | `gitleaks/gitleaks` rev v8.30.1 | `repo = "local"` / `language = "system"` |
| shellcheck | `shellcheck-py` rev v0.11.0.1 | 同上 |
| actionlint | `rhysd/actionlint` rev v1.7.12 | 同上 |
| zizmor | `zizmorcore/zizmor-pre-commit` rev v1.29.0 | 同上 |
| terraform fmt / validate / tflint | `antonbabenko/pre-commit-terraform` rev v1.99.0 | 変更なし |

`local` に寄せた 4 つは、いずれも upstream の `.pre-commit-hooks.yaml` にある `-system` 相当の定義を写しただけで、
実行される内容は変わらない。実行ファイルは `.mise.toml` で固定済みなので、rev を別に持つ理由がない。

pre-commit-terraform だけリモートに残す。`terraform_validate.sh` の retry / cleanup を自前で持ち直す価値がない。

## 結果

- ツールのバージョンは `.mise.toml` の 1 か所で決まる。`rev` を持つリモートは pre-commit-terraform だけになり、
  そこだけ `prek update` の対象になる
- zizmor 1.29.0 が監査対象にするファイル名は `.pre-commit-config.yaml` と `.pre-commit-config.yml` の 2 つで、
  `prek.toml` は含まれない。[0012](0012-zizmor-for-actions-security.md) に書いた「フック設定自体も監査される」は
  成立しなくなる。代わりに可変な参照が入り込む余地を上記の 1 か所まで減らした。zizmor が `prek.toml` を
  読むようになったら見直す
- `.ryl.toml` の `[rules]` は書いたルールだけが有効になる。yamllint の `extends: default` と逆なので、
  既定値のままのルールも省略できない
- `.tftpl` の除外は `.ryl.toml` の `ignore` に移した。prek は `.tftpl` を YAML と判定しないのでフックには渡らないが、
  `ryl` を直接叩くとエラーになるため設定側で落とす
