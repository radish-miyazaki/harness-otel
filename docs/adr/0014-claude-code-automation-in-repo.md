# 0014: Claude Code の設定はリポジトリに入れ、MCP は読み取りに限る

- 状態: 採用
- 日付: 2026-08-29

## 状況

Claude Code のフックは `.claude/hooks/` に 3 つある（秘密ファイルへの書き込み拒否、破壊的コマンドの確認、編集後の整形）。
一方で、リポジトリ固有の制約のうち次のものは CLAUDE.md の文章にしか存在しない。

- `config/` を変えたら `mise run apply` が要る（[0003](0003-inject-config-via-upload.md)）。忘れると、
  反映されていないダッシュボードを見ながら原因を探すことになる
- ADR の番号は連番で欠番も再利用もしない。次の番号は CLAUDE.md に `（次は NNNN）` と直書きしてあり、
  ADR を足すたびに手で進める必要がある。進め忘れれば次の採番がずれる

また、ダッシュボードとレコーディングルールが正しいかを確かめる手段が `mise run apply` してブラウザで見ることしかない。
パネルのクエリが空を返しているのか、そもそもデータが来ていないのかを、コミット前に区別できない。

## 判断

`.claude/` 配下と `.mcp.json` をコミットし、Claude Code の設定をリポジトリの一部として扱う。
`.claude/settings.local.json`（ハーネス自身のテレメトリ設定）だけは今までどおり gitignore する。

| 置くもの | 内容 |
| --- | --- |
| `.claude/hooks/notify-apply-needed.sh` | `terraform/config/` を編集したら apply が要ることを PostToolUse で伝える |
| `.claude/hooks/check-adr.sh` | ADR のファイル名・採番・目次への追記を突き合わせる。採番違反は `exit 2` で差し戻す |
| `.claude/skills/new-adr/` | 採番、テンプレ展開、目次の行、CLAUDE.md の `（次は NNNN）` までをスクリプトで進める |
| `.claude/skills/add-service/` | `modules/service` を 1 つ足す手順。0002 / 0003 / 0004 / 0008 / 0009 の制約を並べたもの |
| `.claude/agents/collector-privacy-reviewer.md` | scrub 境界の後退だけを見るレビュー担当 |
| `.mcp.json` | Grafana と Docker の MCP サーバー |

### MCP は読み取りに限る

Grafana MCP（`grafana/mcp-grafana:1.3.0`）は `--disable-write` で起動する。目的はパネルの PromQL / LogQL を
実データで叩くことであって、Grafana 上でダッシュボードを編集することではない。ダッシュボードの正は
`config/grafana/dashboards/*.json` で、Grafana 側の変更は次の apply で消える。書けると、その事実が見えなくなる。

Docker MCP（`mcp-server-docker` 0.3.0）はコンテナの作成・削除・ボリューム削除までできる。
コンテナのライフサイクルは Terraform が持っていて、`guard-destructive.sh` が `docker volume rm` を止めているが、
**あのフックは Bash だけを見るので MCP 経由の削除は素通りする**。`.claude/settings.json` の `permissions.deny` で
変更系ツールを名指しで禁じ、`list_containers` / `fetch_container_logs` / `list_images` / `list_networks` /
`list_volumes` の 5 つだけ残す。

### 接続とトークン

Grafana はホスト側に `127.0.0.1:3000` でしか出ていない（[0002](0002-collector-and-loopback-only.md)）。
コンテナから loopback バインドのポートには届かないので、MCP サーバーを `harness-otel` ネットワークに入れて
`http://harness-otel-grafana:3000` を見せる。`smoke-test.sh` が Prometheus と Loki を叩くのと同じやり方。

サービスアカウントトークンは `.env` の `GRAFANA_SERVICE_ACCOUNT_TOKEN` から渡し、`.mcp.json` には
`${GRAFANA_SERVICE_ACCOUNT_TOKEN}` と参照だけ書く（[0004](0004-secrets-from-environment.md)）。権限は Viewer で足りる。

## 結果

- ダッシュボードのクエリをコミット前に実データで検証できる。スタックが起動していないと Grafana MCP は
  起動に失敗する（`--network harness-otel` が解決できない）が、そのときは検証もできないので困らない
- `.mcp.json` はコミットするが、トークンがなければ Grafana MCP は認証に失敗する。トークンは任意で、
  設定しなければ Docker MCP だけが使える
- ネットワーク名 `harness-otel` を `.mcp.json` に直書きした。`var.name_prefix` を変えると解決できなくなる。
  `smoke-test.sh` も同じ既定値を持っているので、変えるならその 2 か所を直す
- `mcp-server-docker` は `uvx` で取る。実行時にダウンロードが走るぶん、mise で固定した他のツールと違って
  初回は遅い。バージョンは `mcp-server-docker@0.3.0` で固定した
- ADR を書く経路が 2 つになった。`new-adr` スクリプトを通れば採番も目次も CLAUDE.md も揃い、
  手で書けば `check-adr.sh` が差し戻す。どちらでも連番は保たれる
- `permissions.deny` はツール名を列挙している。`mcp-server-docker` が変更系ツールを増やしたら、
  既定で許可される側に入る。バージョンを上げるときはツール一覧を見る
