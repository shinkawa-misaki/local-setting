# local-setting
Local environment construction tool by bash-oo-framework

# 構成
```
.
├── localSetting.sh
├── README.md
└── src
    └── app
        ├── commands
        │   ├── alias.sh
        │   ├── docker.sh
        │   ├── modules
        │   │   └── template.sh
        │   ├── ssh.sh
        │   ├── toolInstall.sh
        │   ├── toolUninstall.sh
        │   ├── upgrade.sh
        │   └── zsh.sh
        ├── helpers
        │   ├── dockerProject.sh
        │   └── tool
        │       └── template.sh
        └── lib
            ├── Array
            │   └── Contains.sh
            ├── oo-bootstrap.sh
            ├── util
            │   ├── exception.sh
            │   └── type.sh
            └── util_ext
                ├── alias.sh
                ├── log.sh
                ├── providers.sh
                └── zsh.sh
```


# 使用したブランチ
- master/fix_ticket_2
- entry_point
- commands
- oo_bootstrap
- array_contains_sh
- util_type_exception_sh
- util-ext_log_zsh_alias_providers
- trace_and_tweak (だいぶ慣れて来たので一気に最後まで確認する用のブランチ。)

### 各ファイルから処理を追う
<details>
<summary>localSetting.sh</summary>
・src/app/commands/zsh.sh<br>
・src/app/commands/alias.sh<br>
・src/app/commands/toolInstall.sh<br>
・src/app/commands/toolUnInstall.sh<br>
・src/app/commands/ssh.sh<br>
・src/app/commands/docker.sh<br>
・src/app/commands/upgrade.sh<br>
・src/app/commands/modules/${module}.sh
</details>

<details>
<summary>src/app/commands/modules/${module}.sh</summary>
・src/app/lib/oo-bootstrap.sh<br>
・src/app/lib/util/type.sh<br>
・src/app/lib/util/exception.sh<br>
・src/app/lib/util_ext/log.sh<br>
・src/app/helpers/tool/template.sh<br>
・src/app/helpers/dockerProject.sh
</details>

<details>
<summary>src/app/lib/helpers/tool/template.sh</summary>
・src/app/lib/util_ext/zsh.sh<br>
・src/app/helpers/tool/common.sh
</details>

<details>
<summary>src/app/helpers/dockerProject.sh</summary>
・src/app/lib/util/class.sh<br>
・src/app/lib/util_ext/log.sh<br>
・src/app/lib/util_ext/docker.sh<br>
・src/app/lib/util_ext/providers.sh<br>
・src/app/helpers/yml.sh<br>
・src/app/helpers/env.sh<br>
・src/app/helpers/alias.sh<br>
・src/app/helpers/github.sh<br>
・src/app/helpers/docker.sh<br>
・src/app/helpers/config.sh
</details>
