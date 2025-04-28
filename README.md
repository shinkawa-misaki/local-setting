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
        │   ├── database
        │   ├── dockerProject.sh
        │   ├── ssh
        │   ├── tool
        │   │   └── template.sh
        │   └── yml.sh
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




<table>
<tr>
<th class="left-align">
<details>
<summary>各ファイルから処理を追う</summary>
<details>
<summary class="summary-color2"><b>localSetting.sh</b></summary>
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
<summary class="summary-color2"><b>src/app/commands/modules/${module}.sh</b></summary>
・src/app/lib/oo-bootstrap.sh<br>
・src/app/lib/util/type.sh<br>
・src/app/lib/util/exception.sh<br>
・src/app/lib/util_ext/log.sh<br>
・src/app/helpers/tool/template.sh<br>
・src/app/helpers/dockerProject.sh
</details>
<details>
<summary class="summary-color2"><b>src/app/lib/helpers/tool/template.sh</b></summary>
・src/app/lib/util_ext/zsh.sh<br>
・src/app/helpers/tool/common.sh
</details>
<details>
<summary class="summary-color2"><b>src/app/helpers/dockerProject.sh</b></summary>
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
<details>
<summary class="summary-color2"><b>src/app/helpers/yml.sh</b></summary>
・src/app/lib/util/class.sh<br>
・src/app/lib/util_ext/log.sh<br>
・src/app/lib/util_ext/yml.sh<br>
・src/app/lib/util_ext/grep.sh<br>
・src/app/helpers/config.sh<br>
・src/app/lib/util_ext/providers.sh
</details>
</details>
</tr>
</table>


<style>
.left-align {
  text-align: left;
}
</style>
<style>
.summary-color1 {
    color: brown;
}
</style>
<style>
.summary-color2 {
    color: cyan;
}
</style>
