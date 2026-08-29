resource "docker_image" "collector" {
  name = var.images.collector
}

resource "docker_container" "collector" {
  name    = local.hosts.collector
  image   = docker_image.collector.image_id
  restart = "unless-stopped"

  # 既定のエントリポイントは /etc/otelcol-contrib/config.yaml を読む
  upload {
    file = "/etc/otelcol-contrib/config.yaml"
    content = templatefile("${path.module}/config/otel-collector.yaml.tftpl", {
      loki_host      = local.hosts.loki
      tempo_host     = local.hosts.tempo
      enable_tracing = var.enable_tracing
    })
  }

  ports {
    internal = 4317
    external = var.ports.otlp_grpc
    ip       = var.bind_address
  }
  ports {
    internal = 4318
    external = var.ports.otlp_http
    ip       = var.bind_address
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

  depends_on = [docker_container.loki, docker_container.prometheus]
}
