resource "docker_image" "tempo" {
  count = var.enable_tracing ? 1 : 0
  name  = var.images.tempo
}

resource "docker_container" "tempo" {
  count   = var.enable_tracing ? 1 : 0
  name    = local.hosts.tempo
  image   = docker_image.tempo[0].image_id
  restart = "unless-stopped"

  command = ["-config.file=/etc/tempo/tempo.yaml"]

  upload {
    file = "/etc/tempo/tempo.yaml"
    content = templatefile("${path.module}/config/tempo.yaml.tftpl", {
      retention = "${var.retention_days * 24}h"
    })
  }

  volumes {
    volume_name    = docker_volume.tempo[0].name
    container_path = "/var/tempo"
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
