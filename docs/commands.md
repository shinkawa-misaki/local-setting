# コマンドリファレンス

## 基本構文

```bash
./localSetting.sh <command> <subcommand> [options]
```

---

## init - 初期化コマンド

環境の初期化

| コマンド | 説明 |
|----------|------|
| `init local` | 全環境の段階的初期化（zsh → alias → tool → ssh） |
| `init zsh` | zsh環境の初期化（インストール、設定ファイル作成） |
| `init alias` | エイリアス設定の初期化（.alias作成） |
| `init ssh all` | 全SSH設定の初期化 |
| `init ssh chmod` | SSH鍵のパーミッション設定のみ実行 |
| `init ssh <module>` | 指定モジュールのSSH設定を初期化 |
| `init tool` | 全ツールのインストール（`init tool <name>` のように名前を付けても、すべて入れる） |
| `init <module>` | カスタムモジュールの初期化 |

### init local の実行順序

1. zsh環境の初期化
2. エイリアスの初期化
3. ツールのインストール
4. zshrc_originalの更新
5. SSH設定の初期化
6. シェル再ログイン

進み具合は `INIT_LOCAL_POINT` で管理するが、値は実行中のプロセスの中にしか残らない。
途中で失敗すると止まり、次に実行するとまた最初（zsh）から始まる。
途中から再開したいときは、`INIT_LOCAL_POINT=2 ./localSetting.sh init local` のように番号を指定する（0: zsh, 1: alias, 2: tool, 3: ssh）。

---

## update - 更新コマンド

既存の設定を更新

### zsh関連

| コマンド | 説明 |
|----------|------|
| `update zsh look` | 現在のzsh設定を表示 |
| `update zsh original` | .zshrc_originalを初期化 |
| `update zsh github` | GitHubトークンを更新 |
| `update zsh ldap` | LDAPパスワードを更新 |
| `update zsh passPhrase` | パスフレーズを更新 |
| `update zsh source <file>` | 指定ファイルをsourceとして追加 |

### エイリアス関連

| コマンド | 説明 |
|----------|------|
| `update alias source <file>` | 指定エイリアスファイルを追加 |
| `update alias deploy <module>` | デプロイ用エイリアス設定を更新 |
| `update alias <module>` | 指定モジュールのエイリアスを更新 |

### SSH関連

| コマンド | 説明 |
|----------|------|
| `update ssh all` | 全SSH設定を更新 |
| `update ssh ssh-add` | SSH鍵の再登録 |
| `update ssh <module>` | 指定モジュールのSSH設定を更新 |

### ツール関連

| コマンド | 説明 |
|----------|------|
| `update tool all` | brew update && brew upgrade を実行 |
| `update tool <module>` | 指定モジュールのツールをインストール（`tool<Module>Install` がある場合。例: `template`） |

### モジュール関連

| コマンド | 説明 |
|----------|------|
| `update <module> <subcommand>` | カスタムモジュールの更新 |

---

## delete - 削除コマンド

設定やツールを削除

| コマンド | 説明 |
|----------|------|
| `delete zsh <word>` | zshrc_originalから指定ワードを削除 |
| `delete alias <word>` | エイリアスから指定ワードを削除 |
| `delete tool all` | ツールをまとめてアンインストール（下記） |
| `delete tool <module>` | 指定モジュールのツールをアンインストール（`tool<Module>UnInstall` がある場合。例: `template`） |
| `delete <module>` | カスタムモジュールを削除 |

`delete tool all` は `init tool` で入れていないものも消すので注意:
docker-compose、docker、composer、sequel-pro-nightly、sequel-pro、sequel-ace、Coccinellida、Alfred 5、
findutils、gzip、coreutils、anyenv（`~/.anyenv` と anyenv の rbenv・nodenv を含む）、
session-manager-plugin、awscli、expect、yq、jq、lolcat、tig、`$(brew --prefix)/bin/php-cs-fixer`。
あわせて `.zshrc` から findutils・gzip・coreutils・anyenv の行を消す。

---

## docker - Docker操作コマンド

プロジェクト単位のDocker環境を操作

| コマンド | 説明 |
|----------|------|
| `docker clean` | 全Docker環境を削除 |
| `docker <project> start` | Dockerコンテナを起動 |
| `docker <project> stop` | Dockerコンテナを停止 |
| `docker <project> restart` | Dockerコンテナを再起動 |
| `docker <project> ssh [command]` | コンテナにSSH接続（コマンド実行可） |
| `docker <project> sql [setting] [container]` | データベースにログイン |
| `docker <project> redis [container] [command]` | Redisコンテナに接続 |
| `docker <project> log [container]` | コンテナのログを表示（デフォルト: app） |
| `docker <project> task <command>` | artisanタスクを実行 |
| `docker <project> cc` | キャッシュをクリア |

---

## upgrade - アップグレードコマンド

環境全体のアップグレード

| コマンド | 説明 |
|----------|------|
| `upgrade env` | 各モジュールの環境変数設定を更新 |
| `upgrade tool` | 不要ツール削除 → 再インストール → モジュール更新 |
| `upgrade alias` | エイリアス初期化 → 各モジュールのエイリアス更新 |
| `upgrade hooks` | 各モジュールのGitHooks設定を更新 |
| `upgrade test` | テスト環境設定をリセット（anyenv削除等） |
| `upgrade` | このリポジトリを master の最新にする → brew update/upgrade |

> **注意**: 引数なしの `upgrade` は、このリポジトリで `git checkout .`・`git clean -df`・`git checkout master`・`git pull origin` を実行する。
> コミットしていない変更と、Git の管理外のファイルは消える。

---

## clean - クリーンアップコマンド

設定を削除する。`localSetting.sh` からは呼べないので、`LOCAL_SETTING` を設定してスクリプトを直接実行する。

```bash
export LOCAL_SETTING="$(pwd)"   # リポジトリのルートで実行
./src/app/commands/zsh.sh clean
```

| コマンド | 説明 |
|----------|------|
| `zsh.sh clean` | oh-my-zsh をアンインストール（zsh 本体は消さない） |
| `alias.sh clean` | `~/.alias` を削除し、`.zshrc_original` から読み込みの行を消す |
| `ssh.sh clean` | 各モジュールの SSH 設定を消し、`~/.ssh/config` をバックアップから戻す |

---

## インストールされるツールたち

### 小規模CLIツール（installIsolatedTools）

| ツール | 説明 | インストールコマンド |
|--------|------|---------------------|
| tig | Gitビューア | `brew install tig` |
| lolcat | カラフル出力 | `brew install lolcat` |
| jq | JSON処理 | `brew install jq` |
| yq | YAML処理 | `brew install yq` |
| expect | 対話的操作自動化 | `brew install expect` |
| awscli | AWS CLI | `brew install awscli` |
| session-manager-plugin | AWS Session Manager | `brew install --cask session-manager-plugin` |
| anyenv | 言語バージョン管理 | `brew install anyenv` |

### GNU/Linuxツール（installGNULinuxTool）

| ツール | 説明 | インストールコマンド |
|--------|------|---------------------|
| coreutils | GNU版ファイル操作 | `brew install coreutils` |
| gzip | GNU版圧縮/解凍 | `brew install gzip` |
| findutils | GNU版find/locate/xargs | `brew install findutils` |

### アプリケーション（installApps）

| ツール | 説明 | インストールコマンド |
|--------|------|---------------------|
| Sequel Ace | データベースクライアント | `brew install --cask sequel-ace` |

### Docker関連（installDocker）

| ツール | 説明 | インストールコマンド |
|--------|------|---------------------|
| composer | PHPパッケージマネージャ | `brew install composer` |
| docker | Docker CLI（Docker Desktop が入っていれば入れない） | `brew install docker` |

---

## 提供される便利関数（base.sh）

`.alias`を読み込むと使用できる関数

| 関数 | 説明 |
|------|------|
| `localSetting [args]` | localSetting.shを任意の場所から実行 |
| `rebaseDev` | devブランチでリベース |
| `rebaseMaster` | masterブランチでリベース |
| `phpenv <module> <version>` | PHPバージョン切り替え |
| `venvUp <name>` | Python仮想環境を作成・起動 |
| `venvDown` | Python仮想環境を終了 |

---

## 環境変数

スクリプト実行に必要な環境変数

| 変数名 | 説明 |
|--------|------|
| `LOCAL_SETTING` | リポジトリのルートパス（`localSetting.sh` が毎回設定する） |
| `INIT_LOCAL_POINT` | init local の進捗管理（0-4。実行中だけ保持） |

`.zshrc_original` で設定し、スクリプトから使う環境変数

| 変数名 | 使う場所 |
|--------|------|
| `LDAP_USER` | `init ssh all`（`~/.ssh/conf.d/default-config` の User）。空なら実行時に聞かれる |
| `PASS_PHRASE` | `update ssh ssh-add`（`~/.ssh/keys` の鍵を登録するときのパスフレーズ） |
| `GITHUB_TOKEN` | export されるので、`gh` などはログイン済みのアカウントより先にこのトークンを使う |
| `LDAP_STG_PASS` / `LDAP_PRD_PASS` | LDAP のパスワード |

前提: Homebrew がインストール済みであること。`gsed`（gnu-sed）がなければ、初回実行時に自動でインストールされる。

---

## カスタムモジュール

`src/app/commands/modules/` にスクリプトを配置することで、独自のモジュールを追加できる

モジュールは以下のサブコマンドに対応する必要がある
- `init` - 初期化
- `update <type>` - 更新（alias, tool, env, hooks等）
- `delete` - 削除
