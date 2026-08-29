# 0012: GitHub Actions のセキュリティ検査に zizmor を入れる

- 状態: 採用
- 日付: 2026-08-29

## 状況

[0011](0011-pin-actions-to-sha.md) で `uses:` をコミット SHA に書き換えたが、次に誰かが `@v4` と書いても誰も気づかない。0007 で入れた actionlint は構文・式・`run:` の shell を見るツールで、ピン留めや資格情報の残留は対象外。

## 判断

[zizmor](https://github.com/zizmorcore/zizmor) 1.29.0 を足す。GitHub Actions 専用の静的解析で、テンプレートインジェクション、資格情報の漏れ、過剰な権限、可変な参照を見る。actionlint とは見る観点が違うので置き換えではなく併用する。

- `.mise.toml` に `zizmor = "1.29.0"`
- prek のフックは当初 upstream の `zizmorcore/zizmor-pre-commit` rev v1.29.0。[0013](0013-native-configs-for-prek-and-ryl.md) で mise の実行ファイルを直接呼ぶ形にした。`--offline` を明示して手元と CI で結果を揃える
- ネットワークが要る監査だけ CI の専用ステップで回す。`GH_TOKEN` は `github.token`（`contents: read`）で足りる

`unpinned-uses` は既定でハッシュ必須（blanket policy）なので、`zizmor.yml` は置かない。`@v4` に戻すと high の error で落ちる。

オンライン側の `ref-version-mismatch` は、SHA が指すタグと `# vX.Y.Z` コメントの食い違いを見る。0011 で「コメントは検証に使われない」と書いた穴がここで塞がる。

## 結果

- 指摘に従い `actions/checkout` に `persist-credentials: false` を付けた（`artipacked`）。CI は読むだけで push しないので、`GITHUB_TOKEN` を `.git/config` に残す理由がない
- persona は既定の `regular` のまま。`pedantic` / `auditor` で出る `anonymous-definition` と `concurrency-limits` は、この規模の CI では雑音なので拾わない
- zizmor は `.pre-commit-config.yaml` 自体も監査していた。[0013](0013-native-configs-for-prek-and-ryl.md) で `prek.toml` に移したあとは対象外になる
