#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace command

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util-ume/zsh
import helpers/tool

## DECLARATION ##
# ------------------------ #
string -g zshrc_path="$HOME/.zshrc"
string -g zshrc_original_path="$HOME/.zshrc_original"

## MAIN ##
# ------------------------ #
function init_toolUnInstall() {
  unInstallDocker
  unInstallPHP
  unInstallApps
  unInstallGNULinuxTool
  unInstallIsolatedTools
}

function unInstallDocker() {
  # docker-composeをアンインストール
  local is_exist
  local brew_prefix
  local target_dir
  is_exist=$(toolIsExist "brew" "docker-compose")
  brew_prefix="$(brew --prefix)"
  target_dir="${brew_prefix}/share/bash/site-functions"

  if [[ "$is_exist" -eq 0 ]]; then
    if [[ -L "${target_dir}/_docker" ]]; then
      unlink "${target_dir}/_docker"
    fi
    if [[ -L "${target_dir}/_docker-compose" ]]; then
      unlink "${target_dir}/_docker-compose"
    fi
  fi
  local unInstallCommand="brew uninstall docker-compose"
  toolUnInstall "brew" "docker-compose" "$unInstallCommand"

  # dockerをアンインストール
  local unInstallCommand="brew uninstall docker"
  toolUnInstall "brew" "docker" "$unInstallCommand"

  # composerをアンインストール
  local unInstallCommand="brew uninstall composer"
  toolUnInstall "brew" "composer" "$unInstallCommand"
}

function unInstallPHP() {
  local bin_dir
  bin_dir="$(brew --prefix)/bin"

  # php-cs-fixerをアンインストール
  if [[ -e "${bin_dir}/php-cs-fixer" ]]; then
    rm "${bin_dir}/php-cs-fixer"
  fi
}

function unInstallApps() {
  # SequelProをアンインストール
  local unInstallCommand="brew uninstall sequel-pro-nightly"
  toolUnInstall "brew" "sequel-pro-nightly" "$unInstallCommand"

  local unInstallCommand="brew uninstall --cask sequel-pro"
  toolUnInstall "brew" "sequel-pro" "$unInstallCommand"

  # SequelAceをアンインストール
  local unInstallCommand="brew uninstall --cask sequel-ace"
  toolUnInstall "brew" "sequel-ace" "$unInstallCommand"

  # coccinellidaをアンインストール
  local unInstallCommand="brew uninstall coccinellida"
  toolUnInstall "app" "Coccinellida" "$unInstallCommand"
}

function unInstallGNULinuxTool() {
  # GNU/Linux版(find, locate, updatedb, xargs)をアンインストール
  zshrcDeleteWord "findutils"
  local unInstallCommand="brew uninstall findutils"
  toolUnInstall "brew" "findutils" "$unInstallCommand"

  # GNU/Linux版(ファイル圧縮/解凍系)をアンインストール
  zshrcDeleteWord "gzip"
  local unInstallCommand="brew uninstall gzip"
  toolUnInstall "brew" "gzip" "$unInstallCommand"

  # GNU/Linux版(ファイル操作)をアンインストール
  zshrcDeleteWord "coreutils"
  local unInstallCommand="brew uninstall coreutils"
  toolUnInstall "brew" "coreutils" "$unInstallCommand"
}

function unInstallIsolatedTools() {
  local etc_dir
  etc_dir="$(brew --prefix)/etc"

  if ! toolIsExist "brew" "anyenv"; then
    # rbenvをアンインストール
    local unInstallCommand="anyenv uninstall -f rbenv"
    toolUnInstall "anyenv" "rbenv" "$unInstallCommand"

    # nodenvをアンインストール
    local unInstallCommand="anyenv uninstall -f nodenv"
    toolUnInstall "anyenv" "nodenv" "$unInstallCommand"
  fi

  # anyenvをアンインストール
  zshrcDeleteWord "anyenv"
  local unInstallCommand="brew uninstall anyenv"
  toolUnInstall "brew" "anyenv" "$unInstallCommand"

  if [[ -e $etc_dir/anyenv.d ]]; then
    sudo rm -rf $etc_dir/anyenv.d
  fi
  if [[ -e ~/.anyenv ]]; then
    sudo rm -rf ~/.anyenv
  fi

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

if [[ "${1}" = "delete" ]]; then
  case ${2} in
    "all") init_toolUnInstall;;
        *) deleteModules "$2";;
  esac
fi
