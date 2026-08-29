resource "docker_image" "loki" {
  name = var.images.loki
}

resource "docker_container" "loki" {
  name    = local.hosts.loki
  image   = docker_image.loki.image_id
  restart = "unless-stopped"

  command = ["-config.file=/etc/loki/local-config.yaml"]

  upload {
    file = "/etc/loki/local-config.yaml"
    content = templatefile("${path.module}/config/loki.yaml.tftpl", {
      retention = "${var.retention_days * 24}h"
    })
  }

  volumes {
    volume_name    = docker_volume.loki.name
    container_path = "/loki"
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
