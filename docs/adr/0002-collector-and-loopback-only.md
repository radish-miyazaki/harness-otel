# 0002: ハーネスは必ず Collector に送り、ホスト公開は loopback に限る

- 状態: 採用
- 日付: 2026-08-29

## 状況

Claude Code は Prometheus exporter を内蔵しており、Collector なしでもスクレイプできる。
一方で、送信先の変更やプロンプト属性の除去を一箇所でやりたい。

## 判断

- ハーネスは OTLP で Collector にだけ送る。Collector の `attributes/scrub` でプロンプト系属性を落とす
- ホストに公開するのは Collector の 4317 / 4318 と Grafana の 3000 のみで、いずれも `127.0.0.1` にバインドする
- Prometheus と Loki と Tempo はホストにポートを出さない。Grafana からは Docker ネットワーク内の名前で到達する
- Collector のコンテナ内の待ち受けは `0.0.0.0`。仕様書は `127.0.0.1` と書いていたが、コンテナ内で loopback にすると Docker のポート転送が届かない。外部露出はホスト側のバインドで防ぐ

## 結果

- smoke test で Prometheus / Loki を叩くときは、同じネットワークに使い捨てコンテナを置いて中から叩く必要がある（`scripts/smoke-test.sh`）
- Claude Code 内蔵の Prometheus exporter は使わないので、複数セッション同時起動時の 9464 ポート競合（仕様書 Q-4）は気にしなくてよい
