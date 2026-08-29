# terraform

ルートモジュール。Docker ネットワークを 1 つ作り、各コンポーネントを `modules/service` の呼び出しとして並べています。

```text
terraform/
├── versions.tf      terraform / provider の要件
├── providers.tf     provider 設定
├── variables.tf     入力
├── locals.tf        名前・ラベル・ダッシュボード一覧
├── main.tf          ネットワークと 5 つの module 呼び出し
├── outputs.tf       出力
├── .terraform.lock.hcl  provider のバージョンとチェックサム（コミットする）
├── config/          各コンポーネントに埋め込む設定（.tftpl は templatefile で描画）
└── modules/service  イメージ + コンテナ + ボリューム + 設定ファイル埋め込みの共通形
```

以下は terraform-docs による自動生成です。

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

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| collector | ./modules/service | n/a |
| grafana | ./modules/service | n/a |
| loki | ./modules/service | n/a |
| prometheus | ./modules/service | n/a |
| tempo | ./modules/service | n/a |

## リソース

## Resources

| Name | Type |
| ---- | ---- |
| [docker_network.this](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/network) | resource |

## 入力

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| grafana\_admin\_password | Grafana 管理者パスワード。TF\_VAR\_grafana\_admin\_password で渡し、ファイルには書かない | `string` | n/a | yes |
| bind\_address | ホスト側で公開するアドレス。外部から書き込まれないよう loopback に固定する | `string` | `"127.0.0.1"` | no |
| codex\_model\_prices | Codex のトークン単価（USD / 100 万トークン）。Codex はコストを出さないため recording rule で算出する | <pre>map(object({<br/>    input        = number<br/>    cached_input = number<br/>    output       = number<br/>  }))</pre> | <pre>{<br/>  "gpt-5": {<br/>    "cached_input": 0.125,<br/>    "input": 1.25,<br/>    "output": 10<br/>  },<br/>  "gpt-5-mini": {<br/>    "cached_input": 0.025,<br/>    "input": 0.25,<br/>    "output": 2<br/>  }<br/>}</pre> | no |
| docker\_host | Docker デーモンのソケット。OrbStack や Colima など既定と異なる場合に上書きする | `string` | `"unix:///var/run/docker.sock"` | no |
| enable\_tracing | Tempo を起動し Collector に traces パイプラインを追加する（P4） | `bool` | `false` | no |
| grafana\_admin\_user | Grafana 管理者ユーザー名 | `string` | `"admin"` | no |
| images | 各コンポーネントのイメージタグ。更新時はここだけ変える | <pre>object({<br/>    collector  = string<br/>    prometheus = string<br/>    loki       = string<br/>    grafana    = string<br/>    tempo      = string<br/>  })</pre> | <pre>{<br/>  "collector": "otel/opentelemetry-collector-contrib:0.159.0",<br/>  "grafana": "grafana/grafana:13.2.0",<br/>  "loki": "grafana/loki:3.7.7",<br/>  "prometheus": "prom/prometheus:v3.14.0",<br/>  "tempo": "grafana/tempo:3.0.3"<br/>}</pre> | no |
| name\_prefix | コンテナ・ネットワーク・ボリューム名の接頭辞 | `string` | `"harness-otel"` | no |
| ports | ホスト側に公開するポート | <pre>object({<br/>    otlp_grpc = number<br/>    otlp_http = number<br/>    grafana   = number<br/>  })</pre> | <pre>{<br/>  "grafana": 3000,<br/>  "otlp_grpc": 4317,<br/>  "otlp_http": 4318<br/>}</pre> | no |
| retention\_days | Prometheus / Loki / Tempo の保持日数。ディスク肥大を抑える | `number` | `90` | no |

## 出力

## Outputs

| Name | Description |
| ---- | ----------- |
| container\_names | 起動しているコンテナ名。docker logs の引数に使う |
| grafana\_url | n/a |
| otlp\_grpc\_endpoint | Claude Code / Codex の OTEL\_EXPORTER\_OTLP\_ENDPOINT に設定する値 |
| otlp\_http\_endpoint | HTTP で送る場合の値（Codex の otlp-http はこの後ろに /v1/logs を付ける） |
<!-- END_TF_DOCS -->
