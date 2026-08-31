# ADR

設計上の判断と、その時点で分かっていたことを残します。あとで前提が変わったら新しい番号で上書きし、古い方の状態を「置き換え済み」にします。

## 書き方

[template.md](template.md) を `NNNN-英語のケバブケース.md` にコピーして埋め、下の表に 1 行足します。番号は連番で、欠番も再利用もしません。
状態は「採用」か「置き換え済み」。置き換えるときは、新しい方から古い番号へリンクを張ります。

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
| [0011](0011-pin-actions-to-sha.md) | GitHub Actions はコミット SHA で固定する | 採用 |
| [0012](0012-zizmor-for-actions-security.md) | GitHub Actions のセキュリティ検査に zizmor を入れる | 採用 |
| [0013](0013-native-configs-for-prek-and-ryl.md) | prek と ryl は互換形式をやめてネイティブ設定に寄せる | 採用 |
| [0014](0014-claude-code-automation-in-repo.md) | Claude Code の設定はリポジトリに入れ、MCP は読み取りに限る | 採用 |
| [0015](0015-tombi-for-toml.md) | TOML の整形と検査に tombi を入れる | 採用 |
| [0016](0016-session-scoped-counter-aggregation.md) | セッション単位のカウンタは max_over_time で集計する | 採用 |
