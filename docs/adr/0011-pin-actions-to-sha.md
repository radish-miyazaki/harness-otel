# 0011: GitHub Actions はコミット SHA で固定する

- 状態: 採用
- 日付: 2026-08-29

## 状況

`actions/checkout@v4` のようなタグ参照は、タグの指す先が動く。上流のリポジトリが乗っ取られた場合、`v4` を書き換えるだけで CI のランナーに任意のコードが流れる。ワークフローは `contents: read` しか持たないが、ランナーの中では `GITHUB_TOKEN` も mise が入れるツールも触れる。

[0008](0008-pin-image-versions.md) でイメージと provider は固定したのに、CI の依存だけ可変のままだった。

## 判断

`.github/workflows/ci.yml` の `uses:` を 40 桁のコミット SHA で書き、読めるように後ろへ `# vX.Y.Z` を付ける。

| Action | SHA | タグ |
| --- | --- | --- |
| actions/checkout | `3d3c42e5aac5ba805825da76410c181273ba90b1` | v7.0.1 |
| jdx/mise-action | `c2a87611a18de5b3828c5652fe268e992400cb5c` | v4.3.0 |

タグと違って SHA は付け替えられない。SHA を書いておけば、上流で `v7` が別のコミットに移されても CI は元のコードを取り続ける。

固定するにあたって最新のメジャーまで上げた。それまで checkout は v4、mise-action は v2 で、3 メジャーと 2 メジャー分の修正を取り逃していた。間のメジャーはどちらも Actions ランタイムの Node.js 20 → 24 が主で、`install` / `cache` / `persist-credentials` の入力は変わっていない。checkout v7 の破壊的変更は `pull_request_target` と `workflow_run` での fork PR チェックアウト禁止だが、ここは `push` と `pull_request` しか使っていないので影響がない。

## 結果

- 更新は SHA とコメントの両方を書き換える。`gh api repos/<owner>/<repo>/git/ref/tags/<tag> --jq .object.sha` で引ける
- コメントのタグ名は目印であって検証には使われない。SHA を変えずにコメントだけ直すと嘘になるので、必ず一緒に直す
- 0008 と同じく自動更新は入れない。Renovate や Dependabot を足すなら SHA pin を維持したまま更新する設定にする
- タグ参照への逆戻りと、コメントの食い違いは [0012](0012-zizmor-for-actions-security.md) の zizmor が検出する
