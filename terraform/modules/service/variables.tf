variable "name" {
  description = "コンテナ名。同じネットワーク内ではこの名前で解決される"
  type        = string
}

variable "image" {
  description = "イメージ名とタグ"
  type        = string
}

variable "network_name" {
  description = "接続する Docker ネットワーク"
  type        = string
}

variable "command" {
  description = "エントリポイントに渡す引数。null ならイメージの既定"
  type        = list(string)
  default     = null
}

variable "env" {
  description = "環境変数（KEY=VALUE 形式）"
  type        = list(string)
  default     = null
}

variable "ports" {
  description = "ホストに公開するポート。空なら公開しない"
  type = list(object({
    internal = number
    external = number
  }))
  default = []
}

variable "bind_address" {
  description = "公開ポートをバインドするホスト側アドレス"
  type        = string
  default     = "127.0.0.1"
}

variable "data_volume" {
  description = "永続化するパス。null ならボリュームを作らない"
  type = object({
    name           = string
    container_path = string
  })
  default = null
}

variable "files" {
  description = "コンテナ作成時に書き込むファイル。キーはコンテナ内パス、値は内容"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "コンテナに付けるラベル"
  type        = map(string)
  default     = {}
}
