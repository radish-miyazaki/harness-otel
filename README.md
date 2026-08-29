# harness-otel

Claude Code と Codex CLI が出す OpenTelemetry のテレメトリを、手元の PC 1 台で受けて眺めるための基盤です。
Collector / Prometheus / Loki / Grafana を Terraform（Docker provider）で立ち上げます。外部の SaaS には何も送りません。

```
Claude Code ──┐                    ┌─ Prometheus ─┐
              ├─ OTLP ─▶ Collector ┤              ├─▶ Grafana (127.0.0.1:3000)
Codex CLI  ───┘   :4317/:4318      └─ Loki ───────┘
                                   （Tempo は enable_tracing=true のときだけ）
```

仕様書は [docs/spec/harness-observability-spec.md](docs/spec/harness-observability-spec.md)、設計上の判断は [docs/adr](docs/adr) にあります。

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

起動後、Grafana は http://127.0.0.1:3000 で開けます（ユーザー `admin`、パスワードは `.env` の値）。
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
| `mise run lint` | prek で fmt / validate / tflint / gitleaks / yamllint などを一括実行 |
| `mise run hooks-install` | commit 時に上記 lint を走らせる Git フックを入れる |

## 変えたくなりそうな値

すべて `terraform/variables.tf` にあります。`terraform.tfvars`（gitignore 済み）か `TF_VAR_*` で上書きします。

- `retention_days`（既定 90 日）: Prometheus / Loki / Tempo の保持期間
- `ports`: ホスト側のポート。待ち受けアドレスは `bind_address`（既定 `127.0.0.1`）
- `images`: 各イメージのタグ。パッチバージョンまで固定しています
- `enable_tracing`: Tempo を追加し traces パイプラインを有効化（Claude Code 側はベータ）
- `codex_model_prices`: Codex のコスト推計に使う単価（USD / 100 万トークン）

## データの扱い

- プロンプト本文、応答本文、ツール引数はハーネス側の既定で送られません。送る設定にしていても、Collector の `attributes/scrub` が `prompt` / `response` / `body` / `tool_input` などの属性を落とします（`mise run smoke` で確認できます）
- 4317 / 4318 / 3000 はすべて `127.0.0.1` にしか公開しません。Prometheus と Loki はホストにポートを出していません
- `claude_code.cost.usage` は Anthropic が算出する推計値です。請求額ではありません。ダッシュボードにもそう書いてあります

## 未確認の点

- Codex のメトリクス名（`turn_token_usage_sum` など）は Collector の Prometheus exporter を通した後の実名を確認していません。Grafana の Explore で `{__name__=~"codex.*|turn.*"}` を引いて、ダッシュボードのクエリを合わせてください
- Loki 側で Claude Code のイベントは `{service_name="claude-code"} | event_name="..."` の形で引く前提で組んでいます。`service.name` の実値は Explore で確認してください
- Windows ネイティブは試していません（WSL 想定）

## ライセンス

MIT
