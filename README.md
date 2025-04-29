# local-setting
Local environment construction tool by bash-oo-framework

<details>
<summary>構成</summary>

``` 
.
├── localSetting.sh # 固有の設定をまとめたファイル
├── README.md
└── src
    ├── app
    │   ├── commands # 直接呼び出す“コマンド群”をまとめた場所
    │   │   ├── alias.sh
    │   │   ├── docker.sh
    │   │   ├── modules
    │   │   │   └── template.sh # 機能単位のスクリプト群
    │   │   ├── ssh.sh
    │   │   ├── toolInstall.sh
    │   │   ├── toolUninstall.sh
    │   │   ├── upgrade.sh
    │   │   └── zsh.sh
    │   ├── helpers # 汎用的かつ再利用性の高い“補助スクリプト”
    │   │   ├── alias.sh
    │   │   ├── config.sh
    │   │   ├── database
    │   │   │   └── common.sh # データベース接続やマイグレーション等、DB 周りの共通処理。
    │   │   ├── docker.sh
    │   │   ├── dockerProject.sh
    │   │   ├── env.sh
    │   │   ├── github.sh
    │   │   ├── patch.sh
    │   │   ├── spinner.sh
    │   │   ├── ssh
    │   │   │   ├── aws.sh # AWS 用 SSH 設定生成
    │   │   │   ├── common.sh # SSH 共通フック
    │   │   │   └── github.sh # GitHub SSH キー管理
    │   │   ├── tool # ツール導入テンプレートや汎用処理
    │   │   │   ├── common.sh
    │   │   │   └── template.sh
    │   │   ├── yml.sh
    │   │   └── zsh.sh
    │   └── lib # フレームワーク本体およびその拡張モジュールをまとめた場所
    │       ├── Array # 配列操作に特化したユーティリティ群
    │       │   ├── Contains.sh
    │       │   ├── Intersect.sh
    │       │   ├── List.sh
    │       │   └── Reverse.sh
    │       ├── oo-bootstrap.sh # フレームワークの“起動”と“名前空間管理”を担うコアスクリプト
    │       ├── String # 文字列ユーティリティ
    │       │   ├── GetSpaces.sh
    │       │   ├── IsNumber.sh
    │       │   ├── SanitizeForVariable.sh
    │       │   ├── SlashReplacement.sh
    │       │   └── UUID.sh
    │       ├── TypePrimitives # 現在どこからも参照されていない開発中
    │       │   ├── array.sh
    │       │   ├── boolean.sh
    │       │   ├── integer.sh
    │       │   ├── map.sh
    │       │   └── string.sh
    │       ├── UI # コンソール出力の整形や色付け、ウィジェット表示など、ユーザーインターフェース関連
    │       ├── util # フレームワークの“土台”として、他モジュールから多用される
    │       │   ├── bash4.sh
    │       │   ├── class.sh
    │       │   ├── command.sh
    │       │   ├── exception.sh
    │       │   ├── exist.sh
    │       │   ├── log.sh
    │       │   ├── namedParameters.sh
    │       │   ├── pipe.sh
    │       │   ├── test.sh
    │       │   ├── tryCatch.sh
    │       │   ├── type.sh
    │       │   └── variable.sh
    │       └── util_ext # util/ をベースに、awk・grep・gitHub・docker・ssh など外部ツールとの連携を容易にするラッパー集
    │           ├── alias.sh
    │           ├── awk.sh
    │           ├── aws.sh
    │           ├── chmod.sh
    │           ├── convert.sh
    │           ├── date.sh
    │           ├── docker.sh
    │           ├── expect.sh
    │           ├── find.sh
    │           ├── github.sh
    │           ├── grep.sh
    │           ├── gsed.sh
    │           ├── json.sh
    │           ├── log.sh
    │           ├── lolcat.sh
    │           ├── providers.sh
    │           ├── ssh.sh
    │           ├── yml.sh
    │           └── zsh.sh
    ├── config # プロジェクト全体で共通して使う設定ファイル
    └── resource # ASCII アート、テンプレートファイル、アイコン、証明書など、静的なリソースを保管
    
```
</details>

<table>
<tr>
<th class="left-align">
<details>
<summary>使用したブランチ</summary>
・ master/fix_ticket_2<br>
・ trace_and_tweak
</details>
</th>
</tr>
</table>

dockerの構築ができればOK
