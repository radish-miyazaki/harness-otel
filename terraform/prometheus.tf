resource "docker_image" "prometheus" {
  name = var.images.prometheus
}

resource "docker_container" "prometheus" {
  name    = local.hosts.prometheus
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--storage.tsdb.retention.time=${local.retention}",
  ]

  upload {
    file = "/etc/prometheus/prometheus.yml"
    content = templatefile("${path.module}/config/prometheus.yml.tftpl", {
      collector_host = local.hosts.collector
    })
  }

  upload {
    file = "/etc/prometheus/rules/codex-cost.yml"
    content = templatefile("${path.module}/config/prometheus-rules.yml.tftpl", {
      prices = var.codex_model_prices
    })
  }

  volumes {
    volume_name    = docker_volume.prometheus.name
    container_path = "/prometheus"
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
}
