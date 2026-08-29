output "otlp_grpc_endpoint" {
  description = "Claude Code / Codex の OTEL_EXPORTER_OTLP_ENDPOINT に設定する値"
  value       = "http://${var.bind_address}:${var.ports.otlp_grpc}"
}

output "otlp_http_endpoint" {
  description = "HTTP で送る場合の値（Codex の otlp-http はこの後ろに /v1/logs を付ける）"
  value       = "http://${var.bind_address}:${var.ports.otlp_http}"
}

output "grafana_url" {
  value = "http://${var.bind_address}:${var.ports.grafana}"
}

output "container_names" {
  description = "起動しているコンテナ名。docker logs の引数に使う"
  value = concat(
    [module.collector.name, module.prometheus.name, module.loki.name, module.grafana.name],
    [for m in module.tempo : m.name],
  )
}
