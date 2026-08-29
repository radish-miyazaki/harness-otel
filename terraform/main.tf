locals {
  retention = "${var.retention_days}d"

  # コンテナ間はこの名前で解決する。ホスト側公開ポートとは分けて考える
  hosts = {
    collector  = "${var.name_prefix}-collector"
    prometheus = "${var.name_prefix}-prometheus"
    loki       = "${var.name_prefix}-loki"
    grafana    = "${var.name_prefix}-grafana"
    tempo      = "${var.name_prefix}-tempo"
  }

  common_labels = {
    "app.kubernetes.io/part-of" = var.name_prefix
    "managed-by"                = "terraform"
  }
}

resource "docker_network" "this" {
  name     = var.name_prefix
  internal = false
}

resource "docker_volume" "prometheus" {
  name = "${var.name_prefix}-prometheus-data"
}

resource "docker_volume" "loki" {
  name = "${var.name_prefix}-loki-data"
}

resource "docker_volume" "grafana" {
  name = "${var.name_prefix}-grafana-data"
}

resource "docker_volume" "tempo" {
  count = var.enable_tracing ? 1 : 0
  name  = "${var.name_prefix}-tempo-data"
}
