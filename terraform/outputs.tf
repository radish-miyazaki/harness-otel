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
