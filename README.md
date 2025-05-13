# local-setting
Local environment construction tool by bash-oo-framework

<details>
<summary>確認した構成</summary>

``` 
.
├── localSetting.sh
├── README.md
└── src
    ├── app
    │   ├── commands
    │   │   ├── alias.sh
    │   │   ├── docker.sh
    │   │   ├── modules
    │   │   │   └── template.sh
    │   │   ├── ssh.sh
    │   │   ├── toolInstall.sh
    │   │   ├── toolUninstall.sh
    │   │   ├── upgrade.sh
    │   │   └── zsh.sh
    │   ├── helpers
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
    │   └── lib
    │       ├── Array
    │       │   ├── Contains.sh
    │       │   ├── Intersect.sh
    │       │   ├── List.sh
    │       │   └── Reverse.sh
    │       ├── oo-bootstrap.sh
    │       ├── String
    │       │   ├── GetSpaces.sh
    │       │   ├── IsNumber.sh
    │       │   ├── SanitizeForVariable.sh
    │       │   ├── SlashReplacement.sh
    │       │   └── UUID.sh
    │       ├── TypePrimitives
    │       │   ├── array.sh
    │       │   ├── boolean.sh
    │       │   ├── integer.sh
    │       │   ├── map.sh
    │       │   └── string.sh
    │       ├── UI
    │       │   ├── Color.sh
    │       │   ├── Color.var.sh
    │       │   ├── Console.sh
    │       │   └── Cursor.sh
    │       ├── util
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
    │       └── util_ext
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
    │   └── template.json
    └── resource
        ├── alias
        │   └── base.sh
        ├── aws
        │   ├── config.ini
        │   └── credentials.ini
        ├── docker
        │   └── scripts
        │       └── laravel
        │           ├── init-env-local.sh
        │           └── init-local.sh
        ├── modules
        │   └── template
        │       ├── ascii.text
        │       ├── hooks
        │       │   ├── pre-commit
        │       │   └── pre-push
        │       └── server
        │           └── local
        │               └── redis
        │                   └── scripts
        │                       └── redis-clear-keys.sh
        ├── ssh
        │   └── conf.d
        │       ├── default-config
        │       └── github.conf
        └── zsh

```
</details>

<details>
<summary>使用したブランチ</summary>
・ master/fix_ticket_2<br>
・ trace_and_tweak
</details>
