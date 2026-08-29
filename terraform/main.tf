resource "docker_network" "this" {
  name = var.name_prefix
}

module "prometheus" {
  source = "./modules/service"

  name         = local.hosts.prometheus
  image        = var.images.prometheus
  network_name = docker_network.this.name
  labels       = local.labels

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--storage.tsdb.retention.time=${var.retention_days}d",
  ]

  files = {
    "/etc/prometheus/prometheus.yml" = templatefile("${path.module}/config/prometheus.yml.tftpl", {
      collector_host = local.hosts.collector
    })
    "/etc/prometheus/rules/codex-cost.yml" = templatefile("${path.module}/config/prometheus-rules.yml.tftpl", {
      prices = var.codex_model_prices
    })
  }

  data_volume = {
    name           = "${var.name_prefix}-prometheus-data"
    container_path = "/prometheus"
  }
}

module "loki" {
  source = "./modules/service"

  name         = local.hosts.loki
  image        = var.images.loki
  network_name = docker_network.this.name
  labels       = local.labels
  command      = ["-config.file=/etc/loki/local-config.yaml"]

  files = {
    "/etc/loki/local-config.yaml" = templatefile("${path.module}/config/loki.yaml.tftpl", {
      retention = local.retention_hours
    })
  }

  data_volume = {
    name           = "${var.name_prefix}-loki-data"
    container_path = "/loki"
  }
}

module "tempo" {
  source = "./modules/service"
  count  = var.enable_tracing ? 1 : 0

  name         = local.hosts.tempo
  image        = var.images.tempo
  network_name = docker_network.this.name
  labels       = local.labels
  command      = ["-config.file=/etc/tempo/tempo.yaml"]

  files = {
    "/etc/tempo/tempo.yaml" = templatefile("${path.module}/config/tempo.yaml.tftpl", {
      retention = local.retention_hours
    })
  }

  data_volume = {
    name           = "${var.name_prefix}-tempo-data"
    container_path = "/var/tempo"
  }
}

module "collector" {
  source = "./modules/service"

  name         = local.hosts.collector
  image        = var.images.collector
  network_name = docker_network.this.name
  labels       = local.labels
  bind_address = var.bind_address

  ports = [
    { internal = 4317, external = var.ports.otlp_grpc },
    { internal = 4318, external = var.ports.otlp_http },
  ]

  # 既定のエントリポイントは /etc/otelcol-contrib/config.yaml を読む
  files = {
    "/etc/otelcol-contrib/config.yaml" = templatefile("${path.module}/config/otel-collector.yaml.tftpl", {
      loki_host      = local.hosts.loki
      tempo_host     = local.hosts.tempo
      enable_tracing = var.enable_tracing
    })
  }

  depends_on = [module.loki, module.prometheus, module.tempo]
}

module "grafana" {
  source = "./modules/service"

  name         = local.hosts.grafana
  image        = var.images.grafana
  network_name = docker_network.this.name
  labels       = local.labels
  bind_address = var.bind_address

  ports = [{ internal = 3000, external = var.ports.grafana }]

  env = [
    "GF_SECURITY_ADMIN_USER=${var.grafana_admin_user}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
    "GF_ANALYTICS_REPORTING_ENABLED=false",
    "GF_ANALYTICS_CHECK_FOR_UPDATES=false",
    "GF_NEWS_NEWS_FEED_ENABLED=false",
  ]

  # ダッシュボード JSON は Grafana 自身が $${var} 記法を使うため templatefile を通さない
  files = merge(local.dashboards, {
    "/etc/grafana/provisioning/datasources/datasources.yaml" = templatefile("${path.module}/config/grafana/provisioning/datasources/datasources.yaml.tftpl", {
      prometheus_host = local.hosts.prometheus
      loki_host       = local.hosts.loki
      tempo_host      = local.hosts.tempo
      enable_tracing  = var.enable_tracing
    })
    "/etc/grafana/provisioning/dashboards/dashboards.yaml" = file("${path.module}/config/grafana/provisioning/dashboards/dashboards.yaml")
  })

  data_volume = {
    name           = "${var.name_prefix}-grafana-data"
    container_path = "/var/lib/grafana"
  }

  depends_on = [module.prometheus, module.loki]
}
