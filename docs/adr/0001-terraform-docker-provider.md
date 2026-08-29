# 0001: コンテナ管理に Terraform の Docker provider を使う

- 状態: 採用
- 日付: 2026-08-29

## 状況

仕様書は Docker Compose での一括起動を推奨していたが、リポジトリの方針として「構築は可能な限り Terraform で行う」ことが決まっている。
対象はローカル PC 1 台の Docker であり、クラウドリソースは登場しない。

## 判断

`kreuzwerker/docker` provider でネットワーク・ボリューム・コンテナを宣言する。Compose ファイルは置かない。

Terraform か OpenTofu かも迷ったが、手元に Terraform 1.14 が入っていること、provider の動作実績が多いことから Terraform にした。
BSL ライセンスは「Terraform と競合する製品を作る」場合の制約なので、この用途では問題にならない。

## 結果

- 良い点: 変数のバリデーション（パスワード長、bind アドレス）と `templatefile` による設定生成が手に入る。`sensitive` で秘密情報が plan 出力に出ない
- 悪い点: Compose より記述が長い。`docker compose logs` のような一括操作がないので `docker` コマンドを直接使う
- Docker ソケットのパスは環境ごとに違うため `docker_host` 変数で受ける（OrbStack は `~/.orbstack/run/docker.sock`）
