# harness-otel

Claude Code と Codex CLI が出す OpenTelemetry のテレメトリを、手元の PC 1 台で受けて眺めるための基盤です。
Collector / Prometheus / Loki / Grafana を Terraform（Docker provider）で立ち上げます。外部の SaaS には何も送りません。

```text
Claude Code ──┐                    ┌─ Prometheus ─┐
              ├─ OTLP ─▶ Collector ┤              ├─▶ Grafana (127.0.0.1:3000)
Codex CLI  ───┘   :4317/:4318      └─ Loki ───────┘
                                   （Tempo は enable_tracing=true のときだけ）
```

設計上の判断は [docs/adr](docs/adr) にあります（元の仕様書はリポジトリには含めていません）。

## 必要なもの

- Docker（Docker Desktop / OrbStack / Colima など）
- [mise](https://mise.jdx.dev/)。Terraform や lint 類はすべて mise 経由で入り、グローバル環境には触りません

## 起動まで

```sh
mise trust && mise install        # terraform, tflint, prek, gitleaks ほか
cp .env.example .env              # Grafana のパスワードと Docker ソケットを書く
mise run init
mise run apply
mise run smoke                    # ダミーデータを流して Prometheus / Loki に届くか確認
```

`.env` は gitignore 済みで、mise がシェルに読み込みます。パスワードを Terraform のファイルに書く必要はありません。
OrbStack を使っている場合は `TF_VAR_docker_host=unix:///Users/<you>/.orbstack/run/docker.sock` を `.env` に足してください。

起動後、Grafana は <http://127.0.0.1:3000> で開けます（ユーザー `admin`、パスワードは `.env` の値）。
「Harness」フォルダに「コスト」「利用状況」「ガバナンス」「信頼性」の 4 枚が入っています。

## ハーネス側の設定

このリポジトリはバックエンド側だけを扱います。送信側は次のファイルを写して設定してください。

| ハーネス | 書く場所 | サンプル |
| --- | --- | --- |
| Claude Code | `~/.claude/settings.json` の `env` | [examples/claude-settings.json](examples/claude-settings.json) |
| Codex CLI | `~/.codex/config.toml`（プロジェクト配下では無視される） | [examples/codex-config.toml](examples/codex-config.toml) |

OTel の設定は起動時にしか読まれないので、書いたあとはハーネスを再起動します。
手順の詳細と、届かないときの調べ方は [docs/setup.md](docs/setup.md) を見てください。

## よく使うコマンド

| コマンド | 内容 |
| --- | --- |
| `mise run plan` | 変更内容の確認 |
| `mise run apply` | 起動・設定反映（設定ファイルを変えたらこれ） |
| `mise run destroy` | コンテナとネットワークを削除。ボリューム（蓄積データ）は残る |
| `mise run lint` | prek で fmt / validate / tflint / gitleaks / ryl / rumdl などを一括実行 |
| `mise run hooks-install` | commit 時に上記 lint を走らせる Git フックを入れる。フック内で tflint などを呼ぶので、シェルで `mise activate` しておくこと |

## ディレクトリ

```text
terraform/           ルートモジュール（構成は terraform/README.md）
terraform/config/    Collector / Prometheus / Loki / Tempo / Grafana に埋め込む設定
terraform/modules/   コンテナ 1 つ分の共通モジュール
docs/adr/            設計判断の記録
docs/setup.md        P0〜P4 の導入手順
examples/            Claude Code / Codex 側の設定サンプル
scripts/             smoke test
```

## 変えたくなりそうな値

すべて `terraform/variables.tf` にあります。`terraform.tfvars`（gitignore 済み）か `TF_VAR_*` で上書きします。

- `retention_days`（既定 90 日）: Prometheus / Loki / Tempo の保持期間
- `ports`: ホスト側のポート。待ち受けアドレスは `bind_address`（既定 `127.0.0.1`）
- `images`: 各イメージのタグ。パッチバージョンまで固定しています
- `enable_tracing`: Tempo を追加し traces パイプラインを有効化（Claude Code 側はベータ）
- `codex_model_prices`: Codex のコスト推計に使う単価（USD / 100 万トークン）

## データの扱い

- プロンプト本文、応答本文、ツール引数はハーネス側の既定で送られません。送る設定にしていても、Collector の `attributes/scrub` が `prompt` / `response` / `body` / `tool_input` などの属性を落とします（`mise run smoke` で確認できます）
- Claude Code が付ける `user.email`（OAuth 認証時のメールアドレス）は Collector の `resource/scrub` で落とします。Codex はメールアドレスに加えてツールの引数（`arguments`、シェルコマンド全文）と出力（`output`）をログ属性で送ってくるので、これも `attributes/scrub` で落とします
- 4317 / 4318 / 3000 はすべて `127.0.0.1` にしか公開しません。Prometheus と Loki はホストにポートを出していません
- `claude_code.cost.usage` は Anthropic が算出する推計値です。請求額ではありません。ダッシュボードにもそう書いてあります

## 未確認の点

- Codex 0.150 は `[otel] exporter` だけではログしか送ってきません（メトリクスは 0 件）。ダッシュボードの Codex 系パネルはすべて Loki のイベントから集計しています。`metrics_exporter` キーで metrics が出るようになったら Prometheus 側に切り替える予定です
- Windows ネイティブは試していません（WSL 想定）

## ライセンス

MIT
