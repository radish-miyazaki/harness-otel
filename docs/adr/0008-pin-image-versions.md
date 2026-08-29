# 0008: イメージはパッチバージョンまで固定する

- 状態: 採用
- 日付: 2026-08-29

## 状況

`latest` タグで動かすと、ある日 `terraform apply` した瞬間に Grafana のメジャーバージョンが上がる。Loki はスキーマ設定の互換性が版で変わる。

## 判断

`images` 変数にパッチバージョンまで書く。2026-08-29 時点の最新安定版:

| コンポーネント | タグ |
| --- | --- |
| Collector (contrib) | 0.159.0 |
| Prometheus | v3.14.0 |
| Loki | 3.7.7 |
| Grafana | 13.2.0 |
| Tempo | 3.0.3 |

## 結果

- 更新は `images` を書き換えて `mise run plan` で差分を見てから apply
- 自動更新は入れない。Renovate を足すなら `images` の既定値を対象にする
