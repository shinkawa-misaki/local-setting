#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace command

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util-ume/log
import util-ume/zsh
import util-ume/alias
import util-ume/providers

## DECLARATION ##
# ------------------------ #
string -g alias_path="$HOME/.alias"
string -g base_alias_path="$(resourceAlias)/base"
string -g zshrc_original_path="$HOME/.zshrc_original"

## MAIN ##
# ------------------------ #
# alias設定を初期化する
function cleanUp() {
  outputInfoLog "init alias start"

  local back_up_path="${alias_path}_${USER}_bk"
  # .aliasファイルのバックアップを取得（初回のみ）
  if [[ -f "$alias_path" && ! -f "$back_up_path" ]]; then
    outputInfoLog "back up $alias_path to $back_up_path"
    cp "$alias_path" "$back_up_path"
    outputResultLog $? "back up $alias_path to $back_up_path"
  fi

  outputStartLog "copy  -f .alias"
  cp -f "$base_alias_path" "$alias_path"
  outputResultLog $? "copy -f.alias"

  # .zshrc_originalに.aliasを追加
  zshrcOriginalAddSourceFile "$alias_path"
}

# 指定したalias設定ファイルを追加する
function aliasAddSource() {
  string add_alias_path="$1"

  # 指定したaliasファイルが存在しない場合エラー終了
  if [[ ! -e "${add_alias_path}" ]]; then
    echo "alias setting is not found : $add_alias_path" && exit
  fi

  outputInfoLog "update alias to ${add_alias_path##*/}"
  cp -f $add_alias_path $HOME
  outputResultLog $? "update alias to ${add_alias_path##*/}"
  # .aliasに指定ファイルをsourceとして追加
  aliasAddSourceFile "$HOME/${add_alias_path##*/}"
}

# モジュールごとにalias設定を更新する
function updateModules() {
  string module="$(echo "${1}" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  string module_shell_path="${2:-${BASH_SOURCE[0]%/*}/modules/$module.sh}"

  # 指定されたモジュールスクリプトが存在しない場合エラー終了
  if [[ ! -e "$module_shell_path" ]]; then
    echo "update alias deploy setting is not found $1" && exit
  fi

  $module_shell_path update alias
}

# デプロイ用のalias設定を更新する
function updateModulesDeploy() {
  string module="$(echo "${1}" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  aliasAddSource "$(resourceModules)/$module/.alias_$1-deploy"
}

# alias設定を削除する
function remove() {
  outputInfoLog "$remove_alias_path unsetting start..."

  # 設定ファイルが存在する場合は削除
  if [[ -e "$remove_alias_path" ]]; then
    outputInfoLog "rm $remove_alias_path"
    rm $remove_alias_path
  fi

  # .zshrc_originalから.aliasの記述を削除
  zshrcOriginalDeleteWord ".alias"

  outputInfoLog "$remove_alias_path unsetting complete!"
}

# 第一引数に「init」が指定された場合、aliasを初期化
if [[ "${1}" == "init" ]]; then
  cleanUp
fi

# 第一引数に「update」が指定された場合、指定されたalias設定を更新
if [[ "${1}" == "update" ]]; then
  case ${2} in
    "source") aliasAddSource "${3}";;       # 指定されたsourceを追加
    "deploy") updateModulesDeploy "${3}";;  # 指定されたデプロイ用設定を更新
           *) updateModules "${2}";;        # 指定されたモジュール設定を更新
  esac
fi

# 第一引数に「delete」が指定された場合、指定されたaliasを削除
if [[ "${1}" == "delete" ]]; then
  aliasDeleteWord "${2}"
fi

# 第一引数に「clean」が指定された場合、alias設定を削除
if [[ "${1}" == "clean" ]]; then
  remove
fi
