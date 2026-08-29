# modules/service

Docker コンテナ 1 つ分の共通形。イメージの取得、任意のデータボリューム、設定ファイルの埋め込み、loopback 限定のポート公開をまとめています。
Collector / Prometheus / Loki / Grafana / Tempo はすべてこのモジュールの呼び出しです。

<!-- BEGIN_TF_DOCS -->
## 要件

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9 |
| docker | ~> 3.6 |

## プロバイダー

## Providers

| Name | Version |
| ---- | ------- |
| docker | ~> 3.6 |

## モジュール



## リソース

## Resources

| Name | Type |
| ---- | ---- |
| [docker_container.this](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container) | resource |
| [docker_image.this](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image) | resource |
| [docker_volume.data](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/volume) | resource |

## 入力

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| image | イメージ名とタグ | `string` | n/a | yes |
| name | コンテナ名。同じネットワーク内ではこの名前で解決される | `string` | n/a | yes |
| network\_name | 接続する Docker ネットワーク | `string` | n/a | yes |
| bind\_address | 公開ポートをバインドするホスト側アドレス | `string` | `"127.0.0.1"` | no |
| command | エントリポイントに渡す引数。null ならイメージの既定 | `list(string)` | `null` | no |
| data\_volume | 永続化するパス。null ならボリュームを作らない | <pre>object({<br/>    name           = string<br/>    container_path = string<br/>  })</pre> | `null` | no |
| env | 環境変数（KEY=VALUE 形式） | `list(string)` | `null` | no |
| files | コンテナ作成時に書き込むファイル。キーはコンテナ内パス、値は内容 | `map(string)` | `{}` | no |
| labels | コンテナに付けるラベル | `map(string)` | `{}` | no |
| ports | ホストに公開するポート。空なら公開しない | <pre>list(object({<br/>    internal = number<br/>    external = number<br/>  }))</pre> | `[]` | no |

## 出力

## Outputs

| Name | Description |
| ---- | ----------- |
| container\_id | n/a |
| name | コンテナ名（ネットワーク内のホスト名） |
<!-- END_TF_DOCS -->
