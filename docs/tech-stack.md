# 技術スタック

このリポジトリで使っているツールとコンポーネントの一覧です。
なぜそれを選んだかは [ADR](adr/README.md) に、どう組み合わせているかは [terraform/README.md](../terraform/README.md) にあります。

バージョンは 2 か所に固定されています。ツール類は [.mise.toml](../.mise.toml)、コンテナイメージは [terraform/variables.tf](../terraform/variables.tf) の `images` です。

## 全体像

| 層 | 使うもの |
| --- | --- |
| 構築 | Terraform + Docker provider |
| 収集 | OpenTelemetry Collector（contrib） |
| 保存 | Prometheus（metrics）、Loki（logs）、Tempo（traces、任意） |
| 可視化 | Grafana |
| 開発ツール | mise、prek、GitHub Actions |

送信側は Claude Code と Codex CLI です。どちらも OTLP で Collector に送るだけで、リポジトリはバックエンド側しか持ちません。

## 構築

| 名前 | バージョン | 用途 |
| --- | --- | --- |
| Terraform | 1.14.9（`required_version >= 1.9`） | 構成の記述と適用 |
| kreuzwerker/docker | `~> 3.6`（lock は 3.9.0） | ネットワーク・イメージ・コンテナ・ボリュームの操作 |
| Docker | 任意の実装（Docker Desktop / OrbStack / Colima） | 実行基盤 |

Compose ではなく Terraform を使っています（[ADR 0001](adr/0001-terraform-docker-provider.md)）。
`terraform/main.tf` が Docker ネットワーク 1 つと `modules/service` の呼び出しを並べ、モジュール側は「イメージ + コンテナ + 任意のデータボリューム + 設定ファイル埋め込み」だけを知っています（[ADR 0009](adr/0009-service-module.md)）。

設定ファイルはホストマウントせず、`templatefile` で描画した内容を `docker_container` の `upload` でコンテナ内に書き込みます（[ADR 0003](adr/0003-inject-config-via-upload.md)）。
そのため `terraform/config/` を変えたら `mise run apply` が要ります。

## コンテナ

| コンポーネント | イメージ | 役割 | ホストへの公開 |
| --- | --- | --- | --- |
| OpenTelemetry Collector | `otel/opentelemetry-collector-contrib:0.159.0` | OTLP を受け、属性を落として 3 系統に振り分ける | 4317 / 4318 |
| Prometheus | `prom/prometheus:v3.14.0` | metrics の保存と recording rule | なし |
| Loki | `grafana/loki:3.7.7` | logs の保存 | なし |
| Grafana | `grafana/grafana:13.2.0` | ダッシュボード | 3000 |
| Tempo | `grafana/tempo:3.0.3` | traces の保存（`enable_tracing = true` のときだけ） | なし |

公開先は `bind_address`（既定 `127.0.0.1`）に限ります（[ADR 0002](adr/0002-collector-and-loopback-only.md)）。
イメージはパッチバージョンまで固定しています（[ADR 0008](adr/0008-pin-image-versions.md)）。

### Collector

`terraform/config/otel-collector.yaml.tftpl` に receivers / processors / exporters を書きます。
`memory_limiter` と `batch` のほか、`attributes/scrub` と `resource/scrub` でプロンプト本文・ツール引数・`user.email` を保存前に落とします。ここがプライバシー境界です。

exporter は metrics が `prometheus`（:9464 で Prometheus に読ませる）、logs が `otlphttp/loki`、traces が `otlp/tempo` です。

### Prometheus

`scrape_interval` 30 秒で Collector の :9464 と :8888、自分自身を読みます。
Codex はコストを送ってこないので、`config/prometheus-rules.yml.tftpl` の recording rule が `codex_model_prices` の単価からトークン数をもとに推計します（[ADR 0006](adr/0006-codex-cost-recording-rule.md) / [0010](adr/0010-codex-from-logs.md)）。

### Loki

OTLP を `/otlp` エンドポイントで直接受けます（[ADR 0005](adr/0005-loki-for-events.md)）。
シングルバイナリ構成、ストレージは filesystem、スキーマは tsdb の v13 です。OTLP の属性を structured metadata として持つため `allow_structured_metadata` を有効にし、compactor が `retention_days` を過ぎたものを消します。

### Grafana

データソースとダッシュボードは provisioning で入れます。UI からの編集は `editable: false` で止めています。
ダッシュボード JSON は Grafana 自身が `$${var}` 記法を使うため `templatefile` を通さず、`locals.dashboards` が `fileset` + `file` で読みます。「コスト」「利用状況」「ガバナンス」「信頼性」の 4 枚が入っています。

## ツールチェーン

すべて mise で入れ、グローバルには置きません（[ADR 0007](adr/0007-tooling-mise-prek-actions.md)）。

| ツール | バージョン | 用途 |
| --- | --- | --- |
| terraform | 1.14.9 | 本体 |
| tflint | 0.61.0 | Terraform の静的検査（`terraform` プラグインの recommended） |
| terraform-docs | 0.24.0 | `terraform/README.md` と `modules/service/README.md` の入力・出力表を生成 |
| prek | 0.5.0 | フックの実行基盤（pre-commit 互換） |
| gitleaks | 8.30.1 | 秘密の検出 |
| ryl | 0.21.0 | YAML の検査（`.tftpl` は除外） |
| rumdl | 0.2.62 | Markdown の検査 |
| tombi | 1.4.1 | TOML の整形と検査（[ADR 0015](adr/0015-tombi-for-toml.md)） |
| shellcheck | 0.11.0 | シェルスクリプトの検査 |
| actionlint | 1.7.12 | ワークフローの構文と式 |
| zizmor | 1.29.0 | ワークフローのセキュリティ（[ADR 0012](adr/0012-zizmor-for-actions-security.md)） |
| uv | 0.10.7 | ryl と MCP サーバーの取得に使う |
| jq | 1.8.1 | smoke test での JSON 処理 |

prek の設定は `prek.toml` です。ネイティブ形式で書き、実行ファイルは mise のものを直接呼びます（[ADR 0013](adr/0013-native-configs-for-prek-and-ryl.md)）。
唯一 `terraform_fmt` / `terraform_validate` / `terraform_tflint` だけ pre-commit-terraform をリモート参照しています。

コミットは `mise x -- git commit` で行います。そうしないとフックから tflint などが見えません。

## CI

GitHub Actions で 2 つのジョブを回します。アクションはコミット SHA で固定します（[ADR 0011](adr/0011-pin-actions-to-sha.md)）。

- `lint` — prek を全ファイルに適用したあと、gitleaks を履歴全体に、zizmor と tombi をオンラインで走らせる。フックは手元と結果を揃えるため `--offline` に固定してあり、ネットワークが要る検査はここだけで効く
- `terraform` — Docker なしで `init -backend=false` / `validate` / `fmt -check`

## テスト

`scripts/smoke-test.sh`（`mise run smoke`）だけです。スタック起動中でないと通りません。
OTLP/HTTP にダミーのメトリクスとログを投げ、Prometheus と Loki に届いたことと、`prompt` 属性が落ちていることを確認します。
Prometheus と Loki はホストにポートを出していないので、同じ Docker ネットワークに使い捨てコンテナを置いて叩きます。

## Claude Code

`.claude/` と `.mcp.json` はコミットします（[ADR 0014](adr/0014-claude-code-automation-in-repo.md)）。

- スキル — `new-adr`、`add-service`
- サブエージェント — `collector-privacy-reviewer`（scrub 境界の後退だけを見る）
- フック — 秘密ファイルへの書き込み拒否、破壊的操作の確認、編集後の整形、apply が要ることの通知、ADR の採番違反の差し戻し
- MCP — Grafana（`--disable-write`）と Docker（読み取り系のみ）。どちらもスタック起動中でないと使えない
