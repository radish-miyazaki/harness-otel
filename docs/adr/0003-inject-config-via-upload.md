# 0003: 設定ファイルはホストマウントではなく upload で埋め込む

- 状態: 採用
- 日付: 2026-08-29

## 状況

Collector / Prometheus / Loki / Grafana の設定ファイルをコンテナに渡す方法は、ホストディレクトリのバインドマウントか、Docker provider の `upload` ブロックかの二択。

## 判断

`upload` を使い、`templatefile` で描画した内容をコンテナ作成時に書き込む。

理由:

- バインドマウントは絶対パスが要り、OrbStack や Colima ではホストパスの見え方が違うことがある
- 設定を Terraform の変数（保持日数、Tempo の有無、Codex の単価）から生成したい
- 設定変更が plan の差分として見える

Grafana のダッシュボード JSON だけは `templatefile` を通さず `source` でそのまま渡す。Grafana 自身が `${var}` 記法を使うため、Terraform の補間と衝突する。

## 結果

- 設定を変えると該当コンテナが作り直される。ボリュームは別リソースなのでデータは残る
- ホストのファイルをコンテナが直接読むわけではないので、`terraform apply` を挟まないと反映されない
