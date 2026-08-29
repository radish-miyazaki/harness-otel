# 0006: Codex のコストは Prometheus の recording rule で推計する

- 状態: 採用
- 日付: 2026-08-29

## 状況

Claude Code は `claude_code.cost.usage`（USD 推計）を出すが、Codex には USD 建てのメトリクスがない。
`turn.token_usage` ヒストグラムに `token_type`（input / cached_input / output / reasoning_output）と `model` が付く。

## 判断

Terraform の `codex_model_prices`（USD / 100 万トークン）から Prometheus の recording rule `codex:estimated_cost_usd:rate1h` をモデルごとに生成する。
単価は公式の価格ページを見て手で更新する。為替は Grafana のダッシュボード変数 `usdjpy`（テキストボックス）で掛ける。

Grafana 側で単価を掛ける案もあったが、モデルごとの単価をクエリに埋めるとダッシュボードが読めなくなるので、Prometheus 側に寄せた。

## 結果

- モデルを追加したら `codex_model_prices` に足して `mise run apply`
- `turn_token_usage_sum` というメトリクス名は Collector の Prometheus exporter の命名規則からの推定で、実測していない。届いたら Explore で確認し、名前が違えば `prometheus-rules.yml.tftpl` を直す
- reasoning_output は output と同じ単価として扱いたくなるが、公式の課金区分が確認できるまでは含めない
