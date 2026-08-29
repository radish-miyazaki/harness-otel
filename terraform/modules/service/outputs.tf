output "name" {
  description = "コンテナ名（ネットワーク内のホスト名）"
  value       = docker_container.this.name
}

output "container_id" {
  value = docker_container.this.id
}
