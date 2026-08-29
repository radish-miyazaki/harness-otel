# 0015: TOML の整形と検査に tombi を入れる

- 状態: 採用
- 日付: 2026-08-29

## 状況

[0007](0007-tooling-mise-prek-actions.md) 以降、ファイル種別ごとに検査を足してきた。YAML は ryl、Markdown は rumdl、シェルは shellcheck、ワークフローは actionlint と zizmor。TOML だけ何もない。

その TOML が `.mise.toml` / `prek.toml` / `.rumdl.toml` / `.ryl.toml` / `examples/codex-config.toml` の 5 つになった。うち 4 つはツールの設定そのもので、キーを 1 文字打ち間違えると黙って無視されるか、実行時まで気づかない。

## 判断

[tombi](https://github.com/tombi-toml/tombi) 1.4.1 を入れる。整形・検査・JSON Schema 検証が 1 バイナリで、mise registry（`aqua:tombi-toml/tombi`）にある。

[taplo](https://github.com/tamasfe/taplo) は落とした。TOML 界隈では定番だが taplo-cli の最新が 0.10.0（2025-05）で 1 年以上動きがなく、不完全な TOML を整形すると AST から要素が落ちる既知の問題が残る。整形して壊れうるものを pre-commit に置きたくない。

prek 同梱の `check-toml` だけで済ませる案も落とした。構文しか見ないので、上に書いた「キーの打ち間違い」がまさに素通りする。

| 場所 | コマンド | 見るもの |
| --- | --- | --- |
| prek のフック | `tombi format --offline` / `tombi lint --offline` | 整形、構文、lint ルール |
| CI の専用ステップ | `tombi lint .` | 上記に加えて JSON Schema |

`--offline` の使い分けは zizmor（[0012](0012-zizmor-for-actions-security.md)）に揃えた。ただし理由は違う。zizmor はオンラインで別の検査が増えるが、tombi の `--offline` は**ローカルキャッシュにあるスキーマしか当てない**。キャッシュが空の状態では検証そのものが起きず、黙って通る。手元で確認した挙動は次のとおり。

| 実行 | `.mise.toml` に未知のキーを入れたとき |
| --- | --- |
| `--offline`（キャッシュあり） | 検出する |
| `--offline`（キャッシュ空） | 素通りする |
| オンライン | 検出する |

つまりスキーマ違反を落とす保証があるのは CI の側だけで、手元のフックは整形と構文の担当。

スキーマの強さは配られている JSON Schema 次第で、一律ではない。`.mise.toml` は mise 自身のスキーマが未知キーを拒むので効く。`prek.toml` の `#:schema` が指す schemastore の prek.json は追加キーを許すので、オンラインでも未知キーは通る。`schema.strict = true` を置いても変わらなかったので、設定ファイル（`tombi.toml`）は置かない。

## 結果

- `.ryl.toml` の配列インデントが 4 から 2 に変わった。tombi の既定で、設定では変えない方針なのでそのまま受ける
- **inline table の中で配列を複数行に書くと、tombi が inline table ごと展開して TOML 1.1 の書式にする**。TOML 1.0 のパーサ（Python の `tomllib` など）はこれを読めない。`prek.toml` の `terraform_validate` が該当したので 1 行に畳んだ。`toml-version = "v1.0.0"` も `#:toml-version` コメントディレクティブも展開を止めず、prek の `check-toml` も通してしまうので、機械的な防波堤はない。CLAUDE.md に書いた
- mise registry の追随には遅れがある。本体は 1.5.0 が出ているが registry は 1.4.1 まで。バージョンを上げるときは registry 側を見る
- tombi は v1 到達が最近で更新が速い。整形結果が変わったら、まず ADR のこの節を見直す
