# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Claude Code と Codex CLI の OpenTelemetry テレメトリを、ローカル PC 1 台で受けて可視化する基盤。
Terraform の Docker provider でコンテナを立てる。概要とセットアップ手順は [README.md](README.md)、設計判断は [docs/adr](docs/adr) にある。

## コマンド

すべて mise 経由。グローバルに入れたツールは使わない。

| コマンド | 内容 |
| --- | --- |
| `mise run init` / `plan` / `apply` / `destroy` | `terraform/` での各操作 |
| `mise run lint` | prek で全ファイル検査（fmt / validate / tflint / gitleaks / ryl / rumdl / shellcheck / actionlint / zizmor / terraform-docs） |
| `mise run smoke` | OTLP にダミーを投げ、Prometheus / Loki への到達と scrub を確認 |
| `prek run --all-files <hook-id>` | 個別のフックだけ走らせる（例: `terraform_tflint`, `rumdl`） |

このリポジトリのテストは `scripts/smoke-test.sh`（= `mise run smoke`）だけ。スタック起動中でないと通らない。

コミットは `mise x -- git commit`（または `mise activate` 済みシェル）で行う。そうしないと prek のフックから tflint などが見えない。

## 構成

`terraform/main.tf` が Docker ネットワーク 1 つと `modules/service` の呼び出し 5 つ（collector / prometheus / loki / grafana、`enable_tracing` のとき tempo）を並べる。
`modules/service` は「イメージ + コンテナ + 任意のデータボリューム + 設定ファイル埋め込み」の共通形で、コンポーネント固有の知識を持たない。差分は呼び出し側の `command` / `files` / `ports` に書く。

データの流れ: ハーネス → Collector（:4317/:4318）→ metrics は Prometheus、logs は Loki、traces は Tempo。
Grafana からこの 3 つを読む。コンテナ間は `local.hosts` の名前で解決し、ホストへの公開は `bind_address`（既定 `127.0.0.1`）に限る。Prometheus と Loki はホストにポートを出していない。

設定ファイルは `terraform/config/` に置き、`templatefile` で描画して `docker_container` の `upload` でコンテナ内に埋め込む（ホストマウントしない → ADR 0003）。
そのため **`config/` を変えたら `mise run apply` が要る**。コンテナは作り直される。

## 触るときの注意

- **`.tftpl` は YAML として妥当でない**（Terraform のディレクティブが混ざる）。`prek.toml` の `check-yaml` と `.ryl.toml` で除外済み。新しいテンプレートも同じ拡張子にする
- **Grafana のダッシュボード JSON は `templatefile` を通さない**。Grafana 自身が `$${var}` 記法を使うため、`locals.dashboards` が `fileset` + `file` で読む。`config/grafana/dashboards/*.json` に置けば自動で拾われる
- **`terraform/README.md` と `modules/service/README.md` のマーカー内は terraform-docs の生成物**。手で書かない（rumdl も除外している）。`.tf` を変えると prek が書き換える
- **Collector の `attributes/scrub` と `resource/scrub` がプライバシー境界**。プロンプト本文・ツール引数・`user.email` をここで落とす。属性を増減したら `mise run smoke` で落ちていることを確認する（smoke test は `prompt` が残っていたら失敗する）
- **Codex はメトリクスを送ってこない**（0.150 時点）。Codex 系のパネルはすべて Loki のイベントから集計し、コストは `config/prometheus-rules.yml.tftpl` の recording rule で `codex_model_prices` の単価から推計する（ADR 0006 / 0010）
- **イメージはパッチバージョンまで固定**（`variables.tf` の `images`）。GitHub Actions はコミット SHA で固定（ADR 0008 / 0011）

## 秘密情報

public repo。値をファイルに書かない。

- `grafana_admin_password` は `.env`（gitignore 済み、mise がシェルに読み込む）の `TF_VAR_grafana_admin_password` から渡す。12 文字以上の validation あり
- `.env` / `*.tfvars` / `*.tfstate` / `*.pem` / `*.key` への書き込みは `.claude/hooks/guard-secrets.sh` が拒否する。値の追加が要るときは `*.example` 側に書き、実値はユーザーに入れてもらう
- `terraform destroy` や `docker volume rm` は `.claude/hooks/guard-destructive.sh` が確認を挟む
- ハーネス側（`~/.claude/settings.json`、`~/.codex/config.toml`）の設定はユーザーが行う。リポジトリには `examples/` にサンプルだけ置く

## Git

- タスクは `.claude/worktrees/` 配下に worktree を切って進める（gitignore 済み）。main の作業ツリーを触らないので、lint やスタックの起動状態を巻き込まずに済む
- ブランチ名は `<type>/<簡潔な機能名>`。type はコミットと揃える（例: `feat/add-claude-md`, `chore/harden-github-actions`）
- コミットメッセージは Conventional Commits に従う。`<type>: <要約>` で、要約は他のドキュメントと同じく日本語（例: `chore: prek と ryl の設定をネイティブ形式に移す`）

## 書き方

- ドキュメントもコメントも日本語。AI 臭い表現（「実現」「活用」「包括的」、意味のない三点列挙、両論併記）を避ける
- コードコメントは why だけ。what や変更履歴は書かない
- 設計判断は `docs/adr/` に残す。`template.md` を `NNNN-english-kebab-case.md` にコピーし、`docs/adr/README.md` の表に 1 行足す。番号は連番で欠番も再利用もしない（次は 0014）
- 構築は Terraform。Compose は使わない
