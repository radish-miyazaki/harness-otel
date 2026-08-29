variable "docker_host" {
  description = "Docker デーモンのソケット。OrbStack や Colima など既定と異なる場合に上書きする"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "name_prefix" {
  description = "コンテナ・ネットワーク・ボリューム名の接頭辞"
  type        = string
  default     = "harness-otel"
}

variable "bind_address" {
  description = "ホスト側で公開するアドレス。外部から書き込まれないよう loopback に固定する"
  type        = string
  default     = "127.0.0.1"

  validation {
    condition     = can(cidrnetmask("${var.bind_address}/32"))
    error_message = "IPv4 アドレスを指定してください。"
  }
}

variable "ports" {
  description = "ホスト側に公開するポート"
  type = object({
    otlp_grpc = number
    otlp_http = number
    grafana   = number
  })
  default = {
    otlp_grpc = 4317
    otlp_http = 4318
    grafana   = 3000
  }
}

variable "images" {
  description = "各コンポーネントのイメージタグ。更新時はここだけ変える"
  type = object({
    collector  = string
    prometheus = string
    loki       = string
    grafana    = string
    tempo      = string
  })
  default = {
    collector  = "otel/opentelemetry-collector-contrib:0.159.0"
    prometheus = "prom/prometheus:v3.14.0"
    loki       = "grafana/loki:3.7.7"
    grafana    = "grafana/grafana:13.2.0"
    tempo      = "grafana/tempo:3.0.3"
  }
}

variable "retention_days" {
  description = "Prometheus / Loki / Tempo の保持日数。ディスク肥大を抑える"
  type        = number
  default     = 90
}

variable "enable_tracing" {
  description = "Tempo を起動し Collector に traces パイプラインを追加する（P4）"
  type        = bool
  default     = false
}

variable "grafana_admin_user" {
  description = "Grafana 管理者ユーザー名"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana 管理者パスワード。TF_VAR_grafana_admin_password で渡し、ファイルには書かない"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 12
    error_message = "12 文字以上にしてください。"
  }
}

variable "codex_model_prices" {
  description = "Codex のトークン単価（USD / 100 万トークン）。Codex はコストを出さないため recording rule で算出する"
  type = map(object({
    input        = number
    cached_input = number
    output       = number
  }))
  default = {
    "gpt-5"      = { input = 1.25, cached_input = 0.125, output = 10.0 }
    "gpt-5-mini" = { input = 0.25, cached_input = 0.025, output = 2.0 }
  }
}
