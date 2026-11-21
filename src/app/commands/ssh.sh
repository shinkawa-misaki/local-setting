#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace commands

## IMPORT ##
# ------------------------ #
import util/type
import util_ext/json
import util_ext/gsed
import util/exception
import util_ext/lolcat
import util_ext/providers
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

# ~/.ssh/keys の鍵のうち、まだ ssh-agent に登録されていないものだけを登録する。
# .zshrc_original からシェルを開くたびに呼ばれるので、
# 自分で登録した鍵（~/.ssh/id_ed25519 など）を消す ssh-add -D はしない
function cleanUpSSHAdd() {
  local key_paths
  key_paths="$(find "$ssh_key_dir" -type f -not -name "*.pub" -not -name ".DS_Store" -print 2> /dev/null || true)"
  # 登録する鍵がなければ何もしない
  if [[ -z "$key_paths" ]]; then
    return 0
  fi

  cleanSSHChmod

  # 登録済みの鍵の一覧（1件もないと ssh-add -l は 1 を返すので、止まらないようにする）
  local loaded_keys
  loaded_keys="$(ssh-add -l 2> /dev/null || true)"

  local key_path
  while read -r key_path <&3; do
    # 公開鍵があれば fingerprint を比べて、登録済みなら飛ばす
    if [[ -f "${key_path}.pub" ]]; then
      local fingerprint
      fingerprint="$(ssh-keygen -lf "${key_path}.pub" 2> /dev/null | awk '{print $2}')"
      if [[ -n "$fingerprint" && "$loaded_keys" == *"$fingerprint"* ]]; then
        continue
      fi
    fi
    exSSHAdd "$key_path"
  done 3<<< "$key_paths"
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
