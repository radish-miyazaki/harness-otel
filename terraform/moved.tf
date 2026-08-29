# 単一ファイル構成から modules/service へ移した際の state の引き継ぎ。
# 全員が apply し終えたら消してよい。
moved {
  from = docker_image.collector
  to   = module.collector.docker_image.this
}
moved {
  from = docker_container.collector
  to   = module.collector.docker_container.this
}
moved {
  from = docker_image.prometheus
  to   = module.prometheus.docker_image.this
}
moved {
  from = docker_container.prometheus
  to   = module.prometheus.docker_container.this
}
moved {
  from = docker_volume.prometheus
  to   = module.prometheus.docker_volume.data[0]
}
moved {
  from = docker_image.loki
  to   = module.loki.docker_image.this
}
moved {
  from = docker_container.loki
  to   = module.loki.docker_container.this
}
moved {
  from = docker_volume.loki
  to   = module.loki.docker_volume.data[0]
}
moved {
  from = docker_image.grafana
  to   = module.grafana.docker_image.this
}
moved {
  from = docker_container.grafana
  to   = module.grafana.docker_container.this
}
moved {
  from = docker_volume.grafana
  to   = module.grafana.docker_volume.data[0]
}
moved {
  from = docker_image.tempo[0]
  to   = module.tempo[0].docker_image.this
}
moved {
  from = docker_container.tempo[0]
  to   = module.tempo[0].docker_container.this
}
moved {
  from = docker_volume.tempo[0]
  to   = module.tempo[0].docker_volume.data[0]
}
