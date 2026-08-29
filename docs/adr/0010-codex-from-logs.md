# 0010: Codex はメトリクスを待たずログから可視化する

- 状態: 採用
- 日付: 2026-08-29

## 状況

Codex 0.150.1 で `~/.codex/config.toml` の `[otel] exporter` を設定したところ、ログ（`service_name="codex_cli_rs"`、scope `codex_otel.log_only`）は届いたが、メトリクスは 1 つも届かなかった。
バイナリには `metrics_exporter` / `trace_exporter` というキー名が埋め込まれているが、公式ドキュメントには記載がなく、書式も確認できていない（仕様書 Q-1）。

一方、ログ側には必要な数値が揃っている。

- `codex.sse_event`（`event_kind="response.completed"`）: `input_token_count` / `cached_token_count` / `output_token_count` / `reasoning_token_count`、`ttft_ms`、`model`
- `codex.api_request`: `success`、`http_response_status_code`、`duration_ms`、`endpoint`
- `codex.tool_result`: `tool_name`、`success`、`duration_ms`
- `codex.tool_decision`: `decision`、`source`（`Config` / `User`）
- `codex.conversation_starts`: `approval_policy`、`sandbox_policy`、`mcp_servers`

## 判断

Codex 系のパネルは Loki のイベントから LogQL（`unwrap` + `sum_over_time` / `quantile_over_time`）で集計する。
Prometheus の recording rule（ADR 0006）は残すが、メトリクスが届くまでは空のまま。`metrics_exporter` の書式が分かり次第、切り替える。

コスト推計はクエリに単価を直書きした。モデルが `gpt-5.5` と表示されており、公表単価が確認できない間は GPT-5 の値を暫定で使う。

## 個人情報の扱い

Codex はログ属性に `user.email`、ツールの引数（`arguments`、シェルコマンド全文）、出力（`output`）を含めてくる。`log_user_prompt = false` はプロンプト本文だけを伏せる設定で、これらには効かない。
Collector の `attributes/scrub` に 3 つを追加して保存前に落とす。`tool_name` と `success` は残るので、ダッシュボードには影響しない。

## 結果

- Codex に関しては AC-4「`codex.api_request` が Prometheus に存在する」を「Loki に存在する」に読み替える
- 修正前に取り込んだログにはメールアドレスとコマンド全文が残っている。消すなら Loki のボリュームを作り直す
