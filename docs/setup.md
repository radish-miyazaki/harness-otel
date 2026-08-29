# 導入手順

仕様書の段階導入（P0〜P4）に沿って進めます。各段階で「何が見えれば次に進めるか」を書いています。

## P0: テレメトリが出ているか確かめる（外部プロセス不要）

Claude Code に console exporter で出力させ、環境変数が効いていることだけを見ます。

```sh
CLAUDE_CODE_ENABLE_TELEMETRY=1 OTEL_METRICS_EXPORTER=console OTEL_METRIC_EXPORT_INTERVAL=1000 claude
```

標準出力に `claude_code.session.count` が流れれば十分です。

## P1: スタックを起動してメトリクスを受ける

README の「起動まで」を実行したあと、`~/.claude/settings.json` に `examples/claude-settings.json` の `env` を写し、Claude Code を再起動します。

確認:

```sh
mise run smoke                       # ダミーデータでの疎通
# 実データ。Grafana → Explore → Prometheus で
claude_code_session_count_total
```

`claude_code_session_count_total` が増えていれば AC-1 達成です。

届かないときは `claude --debug` を実行し、`[3P telemetry]` で始まる行を見ます。`[Anthropic telemetry]` は Anthropic 側の運用テレメトリで、自分の設定とは無関係です。

## P2: イベントを Loki で受ける

`examples/claude-settings.json` には最初から `OTEL_LOGS_EXPORTER=otlp` が入っているので、P1 が通っていれば追加作業はありません。

Grafana → Explore → Loki で:

```logql
{service_name="claude-code"} | event_name="claude_code.user_prompt"
```

プロンプト本文が保存されていないこと（AC-5）は、同じ画面で `|= "prompt"` を含めて検索し、実文が出ないことで確認します。

## P3: Codex を接続する

`examples/codex-config.toml` の `[otel]` を `~/.codex/config.toml` に足して Codex を再起動します。
プロジェクト配下の `.codex/config.toml` に書いても無視されます（起動時に警告が出ます）。

確認は Explore → Prometheus で `{__name__=~"codex.*|turn.*|approval.*"}`。
公式ドキュメントは「ログエクスポート」を主語にしているため、メトリクスが届かない場合は Config Reference を再確認してください。
届いたメトリクス名がダッシュボードのクエリと違っていれば、`terraform/config/grafana/dashboards/*.json` を直して `mise run apply` します。

## P4: トレース（Claude Code ベータ）

```sh
# terraform.tfvars か環境変数で
TF_VAR_enable_tracing=true mise run apply
```

Claude Code 側は `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1` と `OTEL_TRACES_EXPORTER=otlp` を `env` に追加します。
Grafana に Tempo データソースが追加され、Explore から `claude_code.interaction` を起点にたどれます。

## 受け入れ基準の確認方法

| # | 基準 | 確認 |
| --- | --- | --- |
| AC-1 | セッション開始が見える | Explore で `claude_code_session_count_total` |
| AC-2 | モデル別トークン・コスト | コストダッシュボードの「モデル別コスト」 |
| AC-3 | 権限判断の accept / reject | ガバナンスダッシュボード |
| AC-4 | Codex の API リクエスト | Explore で `codex_api_request_total` |
| AC-5 | プロンプト本文が保存されていない | `mise run smoke` の scrub 確認 + Loki 全文検索 |
| AC-6 | 外部から到達不能 | `docker ps` の PORTS 列が `127.0.0.1:` 始まりであること。別ホストから `nc -vz <IP> 4317` が拒否されること |
| AC-7 | 再起動後に自動復帰 | `restart = unless-stopped`。Docker 自体が自動起動する設定になっていることを別途確認 |

## 設定を変えたとき

- `terraform/config/*.tftpl` や `variables.tf` を変えたら `mise run apply`。設定ファイルはコンテナ作成時に埋め込んでいるので、該当コンテナが作り直されます。ボリュームは別リソースなのでデータは残ります
- ダッシュボード JSON を変えたときも同じです。Grafana の UI で編集した内容は保存されない設定（`allowUiUpdates: false`）なので、JSON を直してください

## 片付け

```sh
mise run destroy                     # コンテナ・ネットワークを削除。データは残る
docker volume rm harness-otel-prometheus-data harness-otel-loki-data harness-otel-grafana-data   # データも消す場合
```
