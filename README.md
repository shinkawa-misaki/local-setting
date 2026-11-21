# local-setting

macOS（特に Apple Silicon M1以降）向けの開発環境自動構築・管理システムです。

## 概要

このリポジトリは、開発環境の初期化から継続的な管理までを自動化するシェルスクリプト群です。新しいマシンのセットアップや、複数プロジェクトの開発環境を統一的に管理できます。

## 主な機能

| 機能 | 説明 |
|------|------|
| **zsh環境設定** | .zshrc、.zprofile の初期化と管理 |
| **エイリアス管理** | 開発用エイリアスの一元管理 |
| **SSH設定** | GitHub、AWS等のSSH鍵・設定の自動管理 |
| **ツールインストール** | Homebrew経由でのCLIツール自動インストール |
| **Docker環境** | プロジェクト単位のDocker環境セットアップ |

## ディレクトリ構成

```
local-setting/
├── localSetting.sh          # メインエントリポイント
├── Dockerfile               # テスト環境用
└── src/
    ├── app/
    │   ├── commands/        # メインコマンド実装
    │   │   ├── zsh.sh       # zsh環境設定
    │   │   ├── alias.sh     # エイリアス設定
    │   │   ├── ssh.sh       # SSH設定
    │   │   ├── toolInstall.sh   # ツールインストール
    │   │   ├── toolUninstall.sh # ツール削除
    │   │   ├── docker.sh    # Docker環境設定
    │   │   └── upgrade.sh   # アップグレード
    │   ├── helpers/         # ヘルパークラス群
    │   └── lib/             # ユーティリティライブラリ
    ├── config/              # 設定テンプレート
    └── resource/            # リソースファイル
        ├── alias/           # エイリアス定義
        ├── zsh/             # zsh設定テンプレート
        ├── ssh/             # SSH設定テンプレート
        └── docker/          # Dockerスクリプト
```

## 使い方

### 基本構文

```bash
./localSetting.sh <command> <subcommand> [options]
```

### 初期化コマンド

```bash
# ローカル環境の段階的初期化（zsh → alias → tool → ssh）
./localSetting.sh init local

# 個別初期化
./localSetting.sh init zsh            # zsh環境
./localSetting.sh init alias          # エイリアス
./localSetting.sh init ssh [module]   # SSH設定（all または特定モジュール）
./localSetting.sh init tool           # ツールインストール（すべて）
./localSetting.sh init <project-name> # プロジェクトの初期化（clone・Docker 環境の構築など）
```

### 更新コマンド

```bash
# zsh関連
./localSetting.sh update zsh original     # zshrc_original を初期化
./localSetting.sh update zsh github       # GitHubトークンを更新
./localSetting.sh update zsh ldap         # LDAPパスワードを更新

# エイリアス
./localSetting.sh update alias source <file>  # エイリアスファイルを追加

# SSH
./localSetting.sh update ssh all          # 全SSH設定を更新
./localSetting.sh update ssh <module>     # 特定モジュールのSSH設定を更新
```

### Docker関連

```bash
./localSetting.sh docker <project-name> start  # コンテナを起動（stop / restart / ssh / sql / log なども）
./localSetting.sh docker clean                 # 全Docker環境をクリーンアップ
```

プロジェクトの Docker 環境を作るのは `init <project-name>` です。`src/config/<project-name>.json` と `src/app/commands/modules/<project-name>.sh` が必要です（リポジトリには `template` だけがあります）。

### 削除コマンド

```bash
./localSetting.sh delete zsh <word>    # .zshrc_original から <word> を含む行を削除
./localSetting.sh delete alias <word>  # .alias から <word> を含む行を削除
./localSetting.sh delete tool all      # ツールをまとめてアンインストール（init tool で入れていないものも消す）
./localSetting.sh delete <project-name> # プロジェクトと Docker 環境を削除
```

コマンドの一覧と注意点は [docs/commands.md](docs/commands.md) にあります。

## インストールされるツール

### 小規模CLIツール（Homebrew経由）

- tig（Gitビューア）
- lolcat（カラフル出力）
- jq（JSON処理）
- yq（YAML処理）
- expect（対話的操作自動化）
- coreutils・findutils・gzip（GNU版。coreutils と findutils は `.zshrc` の PATH に追加され、`ls` や `find` などが GNU 版になる）

### 主要ツール

- AWS CLI
- Docker CLI（Docker Desktop が入っていればインストールしない）
- composer（PHP パッケージマネージャ）
- anyenv（言語バージョン管理）
- session-manager-plugin（AWS Session Manager）
- Sequel Ace（データベースクライアント）

## 技術スタック

- **言語**: Bash シェルスクリプト
- **設定形式**: JSON / YAML
- **フレームワーク**: カスタムOOPフレームワーク（oo-bootstrap.sh）
- **パッケージ管理**: Homebrew
- **コンテナ**: Docker / Docker Compose

## 対応環境

- macOS（Apple Silicon M1/M2/M3 対応）
- Docker コンテナ環境（Ubuntu 22.04）

**前提**: [Homebrew](https://brew.sh) がインストール済みであること。`gsed`（gnu-sed）がなければ、`localSetting.sh` の初回実行時に自動でインストールされます。

## 特徴

- **段階的初期化**: `INIT_LOCAL_POINT` で進み具合を管理する。途中で失敗したときは、`INIT_LOCAL_POINT=2 ./localSetting.sh init local` のように番号を指定すると、その段階から再開できる（指定しないと最初から）
- **モジュール設計**: 機能ごとに分離され、新機能の追加が容易
- **セキュリティ**: 認証情報はプレースホルダ（@XXX@）で管理
- **オブジェクト指向**: Bashでのクラスベース設計による保守性の高いコード

## テスト環境

Docker を使用したテスト環境が利用可能です：

```bash
docker build -t local-setting-test .
docker run -it local-setting-test
```
