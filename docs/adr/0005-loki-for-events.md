# 0005: イベント保存に Loki を使い、OTLP は `/otlp` で受ける

- 状態: 採用
- 日付: 2026-08-29

## 状況

Claude Code のイベント（tool_decision、api_error など）は OTLP logs で届く。保存先の候補は Loki / ClickHouse / OpenSearch。
仕様書では Loki の OTLP 受信パスが未検証（Q-2 / R-5）だった。

## 判断

Loki 3.x を単一バイナリ・filesystem ストレージで動かし、Collector の `otlphttp` exporter から `http://loki:3100/otlp` に送る。
exporter が末尾に `/v1/logs` を付けるので、Loki 側の実パスは `/otlp/v1/logs` になる。

`limits_config.allow_structured_metadata: true` が必須。これがないと OTLP の属性を受けられない。
保持期間は `retention_period` と compactor の `retention_enabled: true` の両方で指定する。

## 結果

- 2026-08-29 に smoke test で確認済み: OTLP で送ったログが `{service_name="smoke-test"}` で引け、`prompt` 属性は Collector で落とされていた
- リソース属性 `service.name` はラベル `service_name` に、ログ属性は structured metadata になる。LogQL は `{service_name="claude-code"} | event_name="tool_result"` の形。Claude Code 2.1 系では `event_name` に `claude_code.` の接頭辞は付かない（実測）
- Claude Code はリソース属性に `user.email` を付けてくる。Prometheus 側にもラベルとして展開されるため、`resource/scrub` プロセッサで metrics / logs 両方から落とす
- 起動直後に `error getting ingester clients err="empty ring"` が 1 回出るが、リングが揃うまでの一時的なもので無視してよい
