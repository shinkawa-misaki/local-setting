# local-setting
Local environment construction tool by bash-oo-framework

# 構成
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
    │   │   │   └── template.sh
    │   │   ├── ssh.sh
    │   │   ├── toolInstall.sh
    │   │   ├── toolUninstall.sh
    │   │   ├── upgrade.sh
    │   │   └── zsh.sh
    │   ├── helpers # 汎用的かつ再利用性の高い“補助スクリプト”
    │   │   ├── alias.sh
    │   │   ├── config.sh
    │   │   ├── database
    │   │   │   └── common.sh
    │   │   ├── docker.sh
    │   │   ├── dockerProject.sh
    │   │   ├── env.sh
    │   │   ├── github.sh
    │   │   ├── patch.sh
    │   │   ├── spinner.sh
    │   │   ├── ssh
    │   │   │   ├── aws.sh
    │   │   │   ├── common.sh
    │   │   │   └── github.sh
    │   │   ├── tool
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
    │       └── util_ext # util の、"より具体的なコマンドラッパー群"
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
    ├── config
    └── resource

```


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



