#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace commands

## IMPORT ##
# ------------------------ #
import util/type
import util-ume/json
import util-ume/gsed
import util/exception
import util-ume/lolcat
import util-ume/providers
import helpers/ssh

## DECLARATION ##
# ------------------------ #
string -g ssh_dir="$HOME/.ssh"
string -g ssh_conf_dir="${ssh_dir}/conf.d"
string -g ssh_key_dir="${ssh_dir}/keys"
string -g common_ssh_dir="$(resourceSSH)"
string -rg common_ssh_conf_dir="${common_ssh_dir}/conf.d"
string -rg common_ssh_key_dir="${common_ssh_dir}/keys"

## MAIN ##
# ------------------------ #
# 成功メッセージを出力する
function outPutSuccess() {
  local speed=5
  local spread=2
  local seed=40

  printAscii "" "$speed" "$spread" "$seed"
}

# SSH設定をクリーンアップ（初期化処理）
function cleanUp() {
  setSSHConfig "$1"
  sshAwsCleanUp "$1"
  sshGithubCleanUp "$1"
  cleanUpSSHAdd
  outPutSuccess
}

# SSH鍵を全て削除後、再登録（必要な場合のみ）
function cleanUpSSHAdd() {
  local res
  res=$(ssh-add -l | grep -c 'RSA' || [[ $? == 1 ]])
  # 登録済みのSSH鍵が3件未満の場合、再登録処理を実施
  if [[ $res -ne 3 ]]; then
    cleanSSHChmod
    ssh-add -D
    find $($var:ssh_key_dir) -type f -not -name "*.pub" -print 2> /dev/null | \
      while read -r key_path
      do
        exSSHAdd "$key_path"
      done
  fi
}

# 全てのSSH設定をアップデートする
function update() {
  # default-configを除く全設定ファイルを更新
  for config_path in $(ls "$ssh_conf_dir" | grep -v "default-config"); do
    local module
    module="$(basename $config_path .conf)"
    updateModules "$module"
  done

  cleanUpSSHAdd
  checkGitHubConnection
  outPutSuccess
}

# 指定モジュールのSSH設定を初期化
function initModules() {
  local module
  module="$(gsReplaceCamelCase "$1")"
  local alias_name="ssh${module}CleanUp"

  # 指定aliasが存在する場合は実行、存在しない場合はエラーメッセージ表示
  local is_exist
  is_exist="$(alias | grep -c "$alias_name" || [[ $? == 1 ]])"
  if [[ "$is_exist" -ne 0 ]]; then
    if eval "$alias_name"; then
      outPutSuccess
    fi
  else
    echo "init ssh setting is not found ${1}"
  fi
}

# 指定モジュールのSSH設定を更新
function updateModules() {
  local module
  module="$(gsReplaceCamelCase "$1")"
  local alias_name="ssh${module}Update"
  shift;

  # 指定aliasが存在する場合は実行、存在しない場合はエラーメッセージ表示
  local is_exist
  is_exist="$(echo "$(alias)" | grep -c "$alias_name" || [[ $? == 1 ]])"
  if [[ "$is_exist" -ne 0 ]]; then
    if eval "$alias_name"; then
      outPutSuccess
    fi
  else
    echo "update ssh setting is not found $1"
  fi
}

function remove() {
  # 各モジュールの削除
  find "$(configDir)" -type f | while read -r json_path; do
    local module_domain
    module_domain="$(basename "$(jsonGetValue "$json_path" ".git.remote_domain")" .git)"

    if [[ -d "$HOME/workspace/$module_domain" ]]; then
      local module
      module="$(gsEscapeKebab "$module_domain")"

      local alias_name="ssh${module}Delete"

      local is_exist
      is_exist="$(echo "$(alias)" | grep -c "$alias_name" || [[ $? == 1 ]])"
      if [[ "$is_exist" -ne 0 ]]; then
        eval "$alias_name"
      else
        echo "update ssh setting is not found $module"
      fi
    fi
  done

  removeAllConfig
}

# 第一引数に「init」が指定された場合、指定モジュールのSSH設定を初期化
if [[ "${1}" == "init" ]]; then
  case ${2} in
      "all") cleanUp "$1";;       # 全SSH設定を初期化
    "chmod") cleanSSHChmod;;      # chmodのみ実行
          *) initModules "${2}";; # 指定モジュールを初期化
  esac
fi

# 第一引数に「update」が指定された場合、指定モジュールのSSH設定を更新
if [[ "${1}" == "update" ]]; then
  case ${2} in
        "all") update ${*:2};;           # 全SSH設定を更新
    "ssh-add") cleanUpSSHAdd;;           # ssh-addを再登録
            *) updateModules ${*:2};;    # 指定モジュールを更新
  esac
fi

# 引数に「clean」が指定された場合、SSH設定を削除
if [[ "${1}" == "clean" ]]; then
  remove
fi
