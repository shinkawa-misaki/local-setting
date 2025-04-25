#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace commands

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util-ume/zsh
import helpers/tool

## DECLARATION ##
# スクリプト全体で使うパスをグローバル変数として宣言
# ------------------------ #
string -g zshrc_path="$HOME/.zshrc"
string -g zshrc_original_path="$HOME/.zshrc_original"

## MAIN ##
# 全アンインストール処理をまとめて実行
# ------------------------ #
function init_toolUnInstall() {
  unInstallDocker
  unInstallPHP
  unInstallApps
  unInstallGNULinuxTool
  unInstallIsolatedTools
}

# Docker／docker-compose／composer を削除
function unInstallDocker() {
  # brew で管理される docker-compose の補完定義を解除
  local is_exist
  local brew_prefix
  local target_dir
  is_exist=$(toolIsExist "brew" "docker-compose")
  brew_prefix="$(brew --prefix)"
  target_dir="${brew_prefix}/share/bash/site-functions"

  #================================================
  #  if [[ "$is_exist" -eq 0 ]]; then
  #     [[ -L "${target_dir}/_docker" ]] && unlink "${target_dir}/_docker"
  #     [[ -L "${target_dir}/_docker-compose" ]] && unlink "${target_dir}/_docker-compose"
  #  fi
  # こんな感じでまとめれると思いました。o(･ω･｡)
  #================================================
  if [[ "$is_exist" -eq 0 ]]; then
    if [[ -L "${target_dir}/_docker" ]]; then
      unlink "${target_dir}/_docker"
    fi

    if [[ -L "${target_dir}/_docker-compose" ]]; then
      unlink "${target_dir}/_docker-compose"
    fi
  fi

#================================================
#  toolUnInstall "brew" "docker-compose" "brew uninstall docker-compose"
#  toolUnInstall "brew" "docker" "brew uninstall docker"
#  toolUnInstall "brew" "composer" "brew uninstall composer"
# こんな感じでまとめれると思いました。o(･ω･｡)スッキリー
#================================================

  # docker-compose 本体をアンインストール
  local unInstallCommand="brew uninstall docker-compose"
  toolUnInstall "brew" "docker-compose" "$unInstallCommand"

  # docker 本体をアンインストール
  local unInstallCommand="brew uninstall docker"
  toolUnInstall "brew" "docker" "$unInstallCommand"

  # composer をアンインストール
  local unInstallCommand="brew uninstall composer"
  toolUnInstall "brew" "composer" "$unInstallCommand"
}

# PHP 関連ツールをアンインストール
function unInstallPHP() {
  local bin_dir
  bin_dir="$(brew --prefix)/bin"

  # php-cs-fixer があれば削除
  if [[ -e "${bin_dir}/php-cs-fixer" ]]; then
    rm "${bin_dir}/php-cs-fixer"
  fi
}

#================================================
#  toolUnInstall "brew" "sequel-pro-nightly" "brew uninstall sequel-pro-nightly"
#  toolUnInstall "brew" "sequel-pro" "--cask brew uninstall sequel-pro"
#  toolUnInstall "brew" "sequel-ace" "--cask brew uninstall sequel-ace"
#  toolUnInstall "app" "Coccinellida" "brew uninstall coccinellida"
# こんな感じでまとめれると思いました。o(･ω･｡)スッキリー
#================================================
# GUIアプリケーションをアンインストール
function unInstallApps() {
  # SequelPro 系
  local unInstallCommand="brew uninstall sequel-pro-nightly"
  toolUnInstall "brew" "sequel-pro-nightly" "$unInstallCommand"

  local unInstallCommand="brew uninstall --cask sequel-pro"
  toolUnInstall "brew" "sequel-pro" "$unInstallCommand"

  # Sequel Ace
  local unInstallCommand="brew uninstall --cask sequel-ace"
  toolUnInstall "brew" "sequel-ace" "$unInstallCommand"

  # Coccinellida
  local unInstallCommand="brew uninstall coccinellida"
  toolUnInstall "app" "Coccinellida" "$unInstallCommand"
}

#================================================
#  zshrcDeleteWord "findutils"
#  toolUnInstall "brew" "findutils" "brew uninstall findutils"
#  zshrcDeleteWord "gzip"
#  toolUnInstall "brew" "gzip" "brew uninstall gzip"
#  zshrcDeleteWord "coreutils"
#  toolUnInstall "brew" "coreutils" "brew uninstall coreutils"

# こんな感じでまとめれると思いました。o(･ω･｡)スッキリー
#================================================
# GNU/Linux 相当ツールをアンインストールし、.zshrc から設定を削除
function unInstallGNULinuxTool() {
  # findutils
  zshrcDeleteWord "findutils"
  local unInstallCommand="brew uninstall findutils"
  toolUnInstall "brew" "findutils" "$unInstallCommand"

  # gzip
  zshrcDeleteWord "gzip"
  local unInstallCommand="brew uninstall gzip"
  toolUnInstall "brew" "gzip" "$unInstallCommand"

  # coreutils
  zshrcDeleteWord "coreutils"
  local unInstallCommand="brew uninstall coreutils"
  toolUnInstall "brew" "coreutils" "$unInstallCommand"
}


# Brew 以外の単体ツール（anyenv, rbenv, nodenv, AWSCLI, etc.）をアンインストール
function unInstallIsolatedTools() {
  local etc_dir
  etc_dir="$(brew --prefix)/etc"

#====================================================
# if ! toolIsExist "brew" "anyenv"; then
#  toolUnInstall "anyenv" "rbenv" "anyenv uninstall -f rbenv"
#  toolUnInstall "anyenv" "nodenv" "anyenv uninstall -f nodenv"
# fi
#
#ここもまとめれると思いました。o(･ω･｡)
#====================================================
   # anyenv 経由の rbenv をアンインストール
  if ! toolIsExist "brew" "anyenv"; then
    local unInstallCommand="anyenv uninstall -f rbenv"
    toolUnInstall "anyenv" "rbenv" "$unInstallCommand"

    # anyenv 経由の nodenvをアンインストール
    local unInstallCommand="anyenv uninstall -f nodenv"
    toolUnInstall "anyenv" "nodenv" "$unInstallCommand"
  fi

#====================================================
# zshrcDeleteWord "anyenv"
# toolUnInstall "brew" "anyenv" "brew uninstall anyenv"
# [[ -d $etc_dir/anyenv.d ]]    && sudo rm -rf $etc_dir/anyenv.d
# [[ -d ~/.anyenv ]]            && sudo rm -rf ~/.anyenv
#ここもこうやってまとめれないかな？？(*/ω＼*)
#====================================================
  # anyenv 本体と設定を削除
  zshrcDeleteWord "anyenv"
  local unInstallCommand="brew uninstall anyenv"
  toolUnInstall "brew" "anyenv" "$unInstallCommand"

  if [[ -e $etc_dir/anyenv.d ]]; then
    sudo rm -rf $etc_dir/anyenv.d
  fi
  if [[ -e ~/.anyenv ]]; then
    sudo rm -rf ~/.anyenv
  fi

#====================================================
#  toolUnInstall "brew" "session-manager-plugin" "brew uninstall --cask session-manager-plugin"
#  toolUnInstall "brew" "awscli"                   "brew uninstall awscli"
#  toolUnInstall "brew" "expect"                   "brew uninstall expect"
#  toolUnInstall "brew" "yq"                       "brew uninstall yq"
#  toolUnInstall "brew" "jq"                       "brew uninstall jq"
#  toolUnInstall "brew" "lolcat"                   "brew uninstall lolcat"
#  toolUnInstall "brew" "tig"                      "brew uninstall tig"
#  toolUnInstall "app"  "Alfred 5"                 "brew uninstall alfred"
#}
#
#ここもこうやってまとめるのはどうかな？？
#====================================================
  # その他ツールをアンインストール
  # session-manager-plugin をアンインストール
  local unInstallCommand="brew uninstall --cask session-manager-plugin"
  toolUnInstall "brew" "session-manager-plugin" "$unInstallCommand"

  # AWS CLI をアンインストール
  local unInstallCommand="brew uninstall awscli"
  toolUnInstall "brew" "awscli" "$unInstallCommand"

  # expectをアンインストール
  local unInstallCommand="brew uninstall expect"
  toolUnInstall "brew" "expect" "$unInstallCommand"

  # yqをアンインストール
  local unInstallCommand="brew uninstall yq"
  toolUnInstall "brew" "yq" "$unInstallCommand"

  # jqをアンインストール
  local unInstallCommand="brew uninstall jq"
  toolUnInstall "brew" "jq" "$unInstallCommand"

  # lolcatをアンインストール
  local unInstallCommand="brew uninstall lolcat"
  toolUnInstall "brew" "lolcat" "$unInstallCommand"

  # tigをアンインストール
  local unInstallCommand="brew uninstall tig"
  toolUnInstall "brew" "tig" "$unInstallCommand"

  # brew caskをアンインストール
  local unInstallCommand="brew uninstall alfred"
  toolUnInstall "app" "Alfred 5" "$unInstallCommand"
}

# delete モードで呼び出されたとき、個別モジュールのアンインストールを実行
function deleteModules() {
  local module
  module="$(gsReplaceCamelCase "$1")"
  local alias_name="tool${module}UnInstall"

  local is_exist=
  is_exist="$(alias | grep -c "$alias_name" || [[ $? == 1 ]])"
  if [[ "$is_exist" -ne 0 ]]; then
    eval "$alias_name"
  else
    echo "update ssh setting is not found ${1}"
  fi
}

# 引数が delete の場合はアンインストールを実行
if [[ "${1}" = "delete" ]]; then
  case ${2} in
    "all") init_toolUnInstall;;
        *) deleteModules "$2";;
  esac
fi
