#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace commands

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util_ext/zsh
import util_ext/gsed
import util_ext/providers
import helpers/tool

## DECLARATION ##
# ------------------------ #
string -g zshrc_path="$HOME/.zshrc"
string -g zshrc_original_path="$HOME/.zshrc_original"

## MAIN ##
# ------------------------ #
function init_toolInstall() {
  installIsolatedTools
  installGNULinuxTool
  installApps
  installDocker
}

# # Brew 経由で使う小さな CLI ツールをインストール
function installIsolatedTools() {
  # tigをインストール
  local installCommand="brew install tig"
  toolInstall "brew" "tig" "$installCommand"

  # lolcatをインストール
  local installCommand="brew install lolcat"
  toolInstall "brew" "lolcat" "$installCommand"

  # jqをインストール
  local installCommand="brew install jq"
  toolInstall "brew" "jq" "$installCommand"

  # yqをインストール
  local installCommand="brew install yq"
  toolInstall "brew" "yq" "$installCommand"

  # expectをインストール
  local installCommand="brew install expect"
  toolInstall "brew" "expect" "$installCommand"

  # AWS CLI の古い残骸を削除して再インストール準備
  toolDeleteSetting "/usr/local/aws-cli"
  toolDeleteSetting "/usr/local/bin/aws"
  toolDeleteSetting "/usr/local/bin/aws_completer"

  # AWS CLI 本体をインストールし、リンクを更新
  local installCommand="brew install awscli"
  toolInstall "brew" "awscli" "$installCommand"
  toolReLink "awscli"

  # session-manager-plugin を cask でインストール
  local installCommand="brew install --cask session-manager-plugin"
  toolInstall "brew" "session-manager-plugin" "$installCommand"

  # anyenv をインストールし、.zshrc に初期設定を追記
  local installCommand="brew install anyenv"
  toolInstall "brew" "anyenv" "$installCommand"
  zshrcAddWord "# anyenv PATH" "^"
  zshrcAddWord "PATH=\$HOME/.anyenv/bin:\$PATH" "^"
  zshrcAddWord "if which anyenv > /dev/null; then eval \"\$(anyenv init -)\"; fi" "^"
  if [[ ! -e  ~/.config/anyenv/anyenv-install ]]; then
    echo "y" | anyenv install --init && eval "$(anyenv init -)"
  fi
}

# GNU/Linux 相当の coreutils系ツールをインストールし、パスを .zshrc に追記?
function installGNULinuxTool() {
  # GNU/Linux版(ファイル操作)をインストール
  local installCommand="brew install coreutils"
  toolInstall "brew" "coreutils" "$installCommand"
  zshrcAddWord "# coreutils" "^"
  zshrcAddWord "PATH=/usr/local/opt/coreutils/libexec/gnubin:\$PATH" "^"
  zshrcAddWord "MANPATH=/usr/local/opt/coreutils/libexec/gnuman:\$MANPATH\n" "^"

  # GNU/Linux版(ファイル圧縮/解凍系)をインストール
  local installCommand="brew install gzip"
  toolInstall "brew" "gzip" "$installCommand"
  zshrcAddWord "# gzip" "^"
  zshrcAddWord "PATH=/usr/local/opt/coreutils/gzip/gnubin:\$PATH" "^"
  zshrcAddWord "MANPATH=/usr/local/opt/coreutils/gzip/gnuman:\$MANPATH\n" "^"

  # GNU/Linux版(find, locate, updatedb, xargs)をインストール
  local installCommand="brew install findutils"
  toolInstall "brew" "findutils" "$installCommand"
  zshrcAddWord "# findutils" "^"
  zshrcAddWord "PATH=/usr/local/opt/coreutils/findutils/gnubin:\$PATH" "^"
  zshrcAddWord "MANPATH=/usr/local/opt/coreutils/findutils/gnuman:\$MANPATH\n" "^"
}

# GUIアプリケーションを cask でインストール
function installApps() {
  local installCommand="brew install --cask sequel-ace"
  toolInstall "app" "Sequel Ace" "$installCommand"
}

# # Docker 本体や関連ツールをインストール／再リンク
function installDocker() {
  local installCommand="brew install composer"
  toolInstall "brew" "composer" "$installCommand"

  # brew の bin ディレクトリを取得
  local bin_dir
  bin_dir="$(brew --prefix)/bin"

  # docker 本体を削除 → インストール → リンク
  toolDeleteSetting "${bin_dir}/docker"
  local installCommand="brew install docker"
  toolInstall "brew" "docker" "$installCommand"
  # リンク確認、失敗時は再インストール
  local res
  res=$(toolReLink "docker" 2> /dev/null || echo "1")
  if [[ "$res" == "1" ]]; then
    toolDeleteSetting "${bin_dir}/docker"
    toolInstall "brew" "docker" "brew reinstall docker"
    toolReLink "docker"
  fi
}

# # update モードで、指定したモジュールだけ再インストール
function updateModules() {
  local module
  module="$(gsReplaceCamelCase "$1")"
  local alias_name="tool${module}Install"

  # # alias が登録されていれば呼び出し、なければnot found
  local is_exist
  is_exist="$(alias | grep -c "$alias_name" || [[ $? == 1 ]])"
  if [[ "$is_exist" -ne 0 ]]; then
    eval "$alias_name"
  else
    echo "update ssh setting is not found ${1}"
  fi
}

# 引数が "init" の場合、一連の初期インストールを実行
if [[ "${1}" = "init" ]]; then
  init_toolInstall
fi

# 引数が "update" の場合、全体アップデート or モジュール単位の更新
if [[ "${1}" = "update" ]]; then
  case ${2} in
    "all") brew update && brew upgrade;;
        *) updateModules "$2";;
  esac
fi
