---
name: add-service
description: スタックにコンテナを 1 つ足す。modules/service の呼び出し、イメージ固定、locals.hosts、設定テンプレート、README の再生成までの手順。Alertmanager や Pyroscope のようなコンポーネントを追加するときに使う。
---

# コンテナを 1 つ足す

`modules/service` は「イメージ + コンテナ + 任意のデータボリューム + 設定ファイル埋め込み」の共通形で、
コンポーネント固有の知識を持たない（ADR 0009）。差分はすべて呼び出し側に書く。

## 先に確かめること

- **本当に足すのか**。Grafana のデータソースを増やすだけ、Collector の exporter を足すだけで済まないか
- **設計判断が要るか**。要るなら先に `new-adr` スキルで ADR を書く。あとから書くと理由が失われる

## 手順

順番に意味がある。5 を飛ばすと設定が反映されず、6 を飛ばすと prek が落ちる。

### 1. イメージを固定する（ADR 0008）

`terraform/variables.tf` の `images` に**パッチバージョンまで**書く。`latest` も `3` も使わない。

```hcl
variable "images" {
  type = object({
    # ...
    alertmanager = string
  })
  default = {
    # ...
    alertmanager = "prom/alertmanager:v0.28.1"
  }
}
```

タグが実在することを確かめてから書く。

```bash
docker manifest inspect prom/alertmanager:v0.28.1 >/dev/null && echo ok
```

### 2. ホスト名を登録する

`terraform/locals.tf` の `hosts` に足す。コンテナ間はこの名前で解決する。

```hcl
alertmanager = "${var.name_prefix}-alertmanager"
```

### 3. 設定ファイルを書く

`terraform/config/<name>.yaml.tftpl` に置く。

- **拡張子は `.tftpl`**。Terraform のディレクティブが混ざり YAML として妥当でないため、`prek.toml` の
  `check-yaml` と `.ryl.toml` で除外されている。`.yaml` で置くと lint が落ちる
- 他コンテナを指す箇所は `${...}` の変数にして、`templatefile` の引数で `local.hosts.*` を渡す。
  ホスト名を直書きしない
- Grafana のダッシュボード JSON だけは例外で `templatefile` を通さない（Grafana 自身が `$${var}` を使う）。
  `config/grafana/dashboards/*.json` に置けば `locals.dashboards` が拾う

### 4. モジュールを呼ぶ

`terraform/main.tf` に既存の呼び出しと同じ並びで足す。

```hcl
module "alertmanager" {
  source = "./modules/service"

  name         = local.hosts.alertmanager
  image        = var.images.alertmanager
  network_name = docker_network.this.name
  labels       = local.labels

  command = ["--config.file=/etc/alertmanager/alertmanager.yml"]

  files = {
    "/etc/alertmanager/alertmanager.yml" = templatefile("${path.module}/config/alertmanager.yaml.tftpl", {
      # local.hosts.* を渡す
    })
  }

  data_volume = {
    name           = "${var.name_prefix}-alertmanager-data"
    container_path = "/alertmanager"
  }

  depends_on = [module.prometheus]
}
```

守ること。

- **`ports` を書くのは、人がブラウザやハーネスから直接叩くものだけ**。Prometheus と Loki は公開していない。
  公開するなら `bind_address = var.bind_address` を必ず添える（既定 `127.0.0.1`、ADR 0002）。
  ホスト側ポートは `variables.tf` の `ports` に足して固定値を散らさない
- 秘密情報は `env` に直書きせず、`sensitive = true` の変数を作って `TF_VAR_*` で渡す（ADR 0004）
- 保存するデータがあるなら `data_volume`。保持期間は `var.retention_days` から引く
- `count` で切り替えるなら Tempo の `enable_tracing` に倣い、参照側は `[for m in module.x : m.name]` になる

### 5. 反映して確かめる

設定はホストマウントではなく upload で埋め込まれる（ADR 0003）ので、**`config/` を変えたら apply が要る**。
コンテナは作り直される。

```bash
mise run plan     # 差分を読む
mise run apply
docker logs harness-otel-alertmanager   # 起動して落ちていないこと
mise run smoke                          # Collector 周りを触ったなら必須
```

`terraform/outputs.tf` の `container_names` に足す必要があるかも見る。

### 6. 生成物と lint を通す

`.tf` を変えたので `terraform/README.md` の入力・出力表が古くなっている。マーカー内は terraform-docs の
生成物なので手で書かず、prek に書き換えさせる。

```bash
mise run lint
```
