# 0004: 秘密情報は環境変数から渡し、リポジトリには置かない

- 状態: 採用
- 日付: 2026-08-29

## 状況

public リポジトリとして公開する。現時点で秘密情報は Grafana の管理者パスワードだけだが、今後ヘッダー付きの exporter などが増える可能性がある。

## 判断

- `grafana_admin_password` は `sensitive = true`、既定値なし。`TF_VAR_grafana_admin_password` で渡す
- 値は `.env`（gitignore 済み）に置き、mise の `_.file = ".env"` でシェルに読み込ませる。`.env.example` だけコミットする
- `*.tfvars` と `*.tfstate` は gitignore。state にはパスワードが平文で入るため
- 三重の防御: gitleaks（prek と CI）、Claude Code の PreToolUse フックで `.env` / `*.tfvars` への書き込みを拒否、`.gitignore`

## 結果

- 初回は `.env` を手で作る手間がある。README に手順を書いた
- CI では Docker がないため apply はせず、`validate` と `fmt -check` に留める。validate だけならパスワード変数は要らない
