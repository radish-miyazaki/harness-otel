resource "docker_image" "this" {
  name = var.image
}

resource "docker_volume" "data" {
  count = var.data_volume == null ? 0 : 1
  name  = var.data_volume.name
}

resource "docker_container" "this" {
  name    = var.name
  image   = docker_image.this.image_id
  restart = "unless-stopped"
  command = var.command
  env     = var.env

  dynamic "upload" {
    for_each = var.files
    content {
      file    = upload.key
      content = upload.value
    }
  }

  dynamic "ports" {
    for_each = var.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      ip       = var.bind_address
    }
  }

  dynamic "volumes" {
    for_each = docker_volume.data
    content {
      volume_name    = volumes.value.name
      container_path = var.data_volume.container_path
    }
  }

  networks_advanced {
    name = var.network_name
  }

  dynamic "labels" {
    for_each = var.labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  # ログ設定はデーモン既定に任せる。読み戻し値との差分で作り直されるのを防ぐ
  lifecycle {
    ignore_changes = [log_opts, log_driver]
  }
}
