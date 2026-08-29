resource "docker_image" "grafana" {
  name = var.images.grafana
}

locals {
  dashboard_files = fileset("${path.module}/config/grafana/dashboards", "*.json")
}

resource "docker_container" "grafana" {
  name    = local.hosts.grafana
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  env = [
    "GF_SECURITY_ADMIN_USER=${var.grafana_admin_user}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
    "GF_ANALYTICS_REPORTING_ENABLED=false",
    "GF_ANALYTICS_CHECK_FOR_UPDATES=false",
    "GF_NEWS_NEWS_FEED_ENABLED=false",
  ]

  upload {
    file = "/etc/grafana/provisioning/datasources/datasources.yaml"
    content = templatefile("${path.module}/config/grafana/provisioning/datasources/datasources.yaml.tftpl", {
      prometheus_host = local.hosts.prometheus
      loki_host       = local.hosts.loki
      tempo_host      = local.hosts.tempo
      enable_tracing  = var.enable_tracing
    })
  }

  upload {
    file   = "/etc/grafana/provisioning/dashboards/dashboards.yaml"
    source = "${path.module}/config/grafana/provisioning/dashboards/dashboards.yaml"
  }

  dynamic "upload" {
    for_each = local.dashboard_files
    content {
      file   = "/var/lib/grafana/dashboards/${upload.value}"
      source = "${path.module}/config/grafana/dashboards/${upload.value}"
    }
  }

  ports {
    internal = 3000
    external = var.ports.grafana
    ip       = var.bind_address
  }

  volumes {
    volume_name    = docker_volume.grafana.name
    container_path = "/var/lib/grafana"
  }

  networks_advanced {
    name = docker_network.this.name
  }

  dynamic "labels" {
    for_each = local.common_labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  depends_on = [docker_container.prometheus, docker_container.loki]
}
