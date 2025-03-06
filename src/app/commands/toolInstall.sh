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
import util-ume/gsed
import util-ume/providers
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

  # AWS CLIをインストール
  toolDeleteSetting "/usr/local/aws-cli"
  toolDeleteSetting "/usr/local/bin/aws"
  toolDeleteSetting "/usr/local/bin/aws_completer"

  local installCommand="brew install awscli"
  toolInstall "brew" "awscli" "$installCommand"
  toolReLink "awscli"

  # session-manager-plugin をインストール
  local installCommand="brew install --cask session-manager-plugin"
  toolInstall "brew" "session-manager-plugin" "$installCommand"

  # anyenvをインストール
  local installCommand="brew install anyenv"
  toolInstall "brew" "anyenv" "$installCommand"
  zshrcAddWord "# anyenv PATH" "^"
  zshrcAddWord "PATH=\$HOME/.anyenv/bin:\$PATH" "^"
  zshrcAddWord "if which anyenv > /dev/null; then eval \"\$(anyenv init -)\"; fi" "^"
  if [[ ! -e  ~/.config/anyenv/anyenv-install ]]; then
    echo "y" | anyenv install --init && eval "$(anyenv init -)"
  fi
}

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

function installApps() {
  # SequelAceをインストール
  local installCommand="brew install --cask sequel-ace"
  toolInstall "app" "Sequel Ace" "$installCommand"
}

function installDocker() {
  # composerをインストール
  local installCommand="brew install composer"
  toolInstall "brew" "composer" "$installCommand"

  local bin_dir
  bin_dir="$(brew --prefix)/bin"

  # dockerをインストール
  toolDeleteSetting "${bin_dir}/docker"
  local installCommand="brew install docker"
  toolInstall "brew" "docker" "$installCommand"
  local res
  res=$(toolReLink "docker" 2> /dev/null || echo "1")
  if [[ "$res" == "1" ]]; then
    toolDeleteSetting "${bin_dir}/docker"
    toolInstall "brew" "docker" "brew reinstall docker"
    toolReLink "docker"
  fi
}

function updateModules() {
  local module
  module="$(gsReplaceCamelCase "$1")"
  local alias_name="tool${module}Install"

  local is_exist
  is_exist="$(alias | grep -c "$alias_name" || [[ $? == 1 ]])"
  if [[ "$is_exist" -ne 0 ]]; then
    eval "$alias_name"
  else
    echo "update ssh setting is not found ${1}"
  fi
}

if [[ "${1}" = "init" ]]; then
  init_toolInstall
fi

if [[ "${1}" = "update" ]]; then
  case ${2} in
    "all") brew update && brew upgrade;;
        *) updateModules "$2";;
  esac
fi
