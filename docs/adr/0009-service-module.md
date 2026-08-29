# 0009: コンテナ 1 つ分を `modules/service` に括り出す

- 状態: 採用
- 日付: 2026-08-29

## 状況

初版はコンポーネントごとに `collector.tf` / `prometheus.tf` … と分け、各ファイルで `docker_image` + `docker_container` + `docker_volume` + `upload` + `labels` を書いていた。5 回ほぼ同じ形が並び、ラベルや restart policy を変えるときに全部を触る必要があった。

## 判断

HashiCorp の標準モジュール構成（`main.tf` / `variables.tf` / `outputs.tf` / `versions.tf` をルートに置き、再利用単位は `modules/` に置く）に揃える。

- ルート: `versions.tf`、`providers.tf`、`variables.tf`、`locals.tf`、`main.tf`（ネットワークと module 呼び出し）、`outputs.tf`、`moved.tf`
- `modules/service`: イメージ・コンテナ・任意のデータボリューム・設定ファイル埋め込み・loopback 限定ポート公開を 1 つにまとめる
- 旧リソースアドレスからの引き継ぎは `moved` ブロックで書き、`terraform plan` で作り直しが出ないことを確認した（Grafana だけは upload の `source` → `content` 切り替えで 1 回作り直し。データはボリュームにあるので消えない）
- コンテナの `log_opts` / `log_driver` は `ignore_changes`。Docker デーモン（OrbStack）が既定値を付けて返すため、放っておくと毎回 replace になる

## 結果

- 新しいコンポーネントは `main.tf` に module 呼び出しを 1 つ足すだけになる
- `moved.tf` は全環境で apply が済んだら削除してよい
- terraform-docs が README の入力・出力表を生成する。手書きの説明はマーカーの外に置く
