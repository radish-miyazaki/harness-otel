locals {
  retention_hours = "${var.retention_days * 24}h"

  # コンテナ間はこの名前で解決する。ホスト側公開ポートとは分けて考える
  hosts = {
    collector  = "${var.name_prefix}-collector"
    prometheus = "${var.name_prefix}-prometheus"
    loki       = "${var.name_prefix}-loki"
    grafana    = "${var.name_prefix}-grafana"
    tempo      = "${var.name_prefix}-tempo"
  }

  labels = {
    "app.kubernetes.io/part-of" = var.name_prefix
    "managed-by"                = "terraform"
  }

  dashboards = {
    for f in fileset("${path.module}/config/grafana/dashboards", "*.json") :
    "/var/lib/grafana/dashboards/${f}" => file("${path.module}/config/grafana/dashboards/${f}")
  }
}
