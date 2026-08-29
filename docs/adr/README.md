# ADR

設計上の判断と、その時点で分かっていたことを残します。あとで前提が変わったら新しい番号で上書きし、古い方の状態を「置き換え済み」にします。

| # | 題名 | 状態 |
| --- | --- | --- |
| [0001](0001-terraform-docker-provider.md) | コンテナ管理に Terraform の Docker provider を使う | 採用 |
| [0002](0002-collector-and-loopback-only.md) | ハーネスは必ず Collector に送り、ホスト公開は loopback に限る | 採用 |
| [0003](0003-inject-config-via-upload.md) | 設定ファイルはホストマウントではなく upload で埋め込む | 採用 |
| [0004](0004-secrets-from-environment.md) | 秘密情報は環境変数から渡し、リポジトリには置かない | 採用 |
| [0005](0005-loki-for-events.md) | イベント保存に Loki を使い、OTLP は `/otlp` で受ける | 採用 |
| [0006](0006-codex-cost-recording-rule.md) | Codex のコストは Prometheus の recording rule で推計する | 採用 |
| [0007](0007-tooling-mise-prek-actions.md) | ツールは mise、Git フックは prek、CI は GitHub Actions | 採用 |
| [0008](0008-pin-image-versions.md) | イメージはパッチバージョンまで固定する | 採用 |
| [0009](0009-service-module.md) | コンテナ 1 つ分を `modules/service` に括り出す | 採用 |
| [0010](0010-codex-from-logs.md) | Codex はメトリクスを待たずログから可視化する | 採用 |
