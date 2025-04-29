namespace helpers/ssh
set -e

## IMPORT ##
# ------------------------ #
import util_ext/log
import util_ext/ssh
import util_ext/gsed
import util_ext/chmod
import util_ext/providers
import helpers/patch

## DECLARATION ##
# ------------------------ #
string -g ssh_dir="$HOME/.ssh"
string -g config_path="${ssh_dir}/config"
string -g ssh_conf_dir="${ssh_dir}/conf.d"
string -rg config_back_up_path="${ssh_dir}/config_${USER}_bk"
string -rg default_config_path="${ssh_conf_dir}/default-config"

## MAIN ##
# ------------------------ #
# ~/.sshの権限をクリーンアップ（安全な権限に設定）
SSHCommon::CleanSSHChmod() {
  outputStartLog "clean ~/.ssh chmod"
  dirAllOwnerOfUser "$ssh_dir"
  dirAllOwnerOfUser "$common_ssh_dir"
  secretDir "$ssh_dir"
  secretDir "$common_ssh_dir"
  secretDirALL "$ssh_key_dir"
  secretDirALL "$common_key_conf_dir"
  publicFilesOfName "$ssh_key_dir" "*.pub"
  publicFilesOfName "$common_ssh_key_dir" "*.pub"
  outputResultLog $? "clean ~/.ssh chmod"
}

# SSH設定ファイルをセットアップ
SSHCommon::SetConfig() {
  # config.dディレクトリがなければ作成
  createSecretDir "$ssh_dir" "$ssh_conf_dir"

  publicDirALL "$ssh_dir"

  # 初期化処理時、デフォルト設定ファイルがあればバックアップして削除
  if [[ "${1}" = "init" && -f "$config_path" ]]; then
    if [[ ! -f "$config_back_up_path" ]]; then
      mv "$config_path" "$config_back_up_path"
    fi
  fi

  # LDAP_USERを設定ファイルに反映
  if [[ ! -f "$ssh_conf_dir/default-config" ]]; then
    copyOfSecretFile "$common_ssh_conf_dir/default-config" "$ssh_conf_dir/default-config"
    if [[ "$LDAP_USER" == "" ]]; then
      inputMsg "LDAP USER:"
      read -r ldapUser
    else
      ldapUser="$LDAP_USER"
    fi
    gsReplaceOFRegExpFirst "@LDAP_USER@" "$ldapUser" "$ssh_conf_dir/default-config"
  fi

  # 設定ファイルを反映（プロジェクト系）
  if [[ "${1}" = "init"  && ! -f "$config_path" && -f "$config_back_up_path" ]]; then
    echo "" > "${ssh_dir}/config"

    # バックアップから差分を適用
    if [[ -f "$config_back_up_path" ]]; then
      patchExecute "$config_path" "$config_back_up_path" "$ssh_conf_dir"
    fi
  fi

  # 設定ファイルを反映（プロジェクト毎）
  SSHCommon::UpdateConfig "Include conf.d/\*.conf"
  # 設定ファイルを反映（共通）
  SSHCommon::UpdateConfig "Include conf.d/default-config"

  secretDirALL "$ssh_dir"
}

# SSH設定ファイルに指定した文字列を追加
SSHCommon::UpdateConfig() {
  local word="$1"
  local log_message="ssh config add $word"

  gsAddUniqueRow "$word\n" "$config_path" "^" "$log_message"
}

SSHCommon::ReMoveAllConfig() {
  # プロジェクトごとの設定ファイルを反映
  publicDirALL "$ssh_dir"

  # バックアップを復元する
  if [[ -f "$config_back_up_path" ]]; then
    mv "$config_back_up_path" "$config_path"
  else
    if [[ -d "$ssh_conf_dir" ]]; then
      local target_files=( $(find "$ssh_conf_dir" -type f -not -name "*default*") )
      echo "${target_files[*]}" >> "$config_path"
      echo -e "${target_files[*]}" | xargs rm
    fi
  fi

  if [[ -f "$config_back_up_path" ]]; then
    cat "$config_back_up_path" >> "$config_path"
    rm "$config_back_up_path"
  fi

  # SSH設定ディレクトリが空の場合は削除
  if [[ -z "$(find "$ssh_conf_dir" -mindepth 1 -print -quit)" ]]; then
    rm -rf "$ssh_conf_dir"
  fi

  # SSHディレクトリ全体のパーミッションを設定
  secretDirALL "$ssh_dir"
}

# SSH設定を更新（指定されたプロジェクトに対して）
SSHCommon::UpdateSetting() {
  outputStartLog "update ssh setting $project_domain"
  local project_domain="$1"

  publicDirALL "$ssh_dir"

  # 更新処理時、既存設定ファイルをバックアップ
  if [[ "${1}" = "update" && -f "$config_path" ]]; then
    if [[ ! -f "$config_back_up_path" ]]; then
      mv "$config_path" "$config_back_up_path"
    fi
  fi

  # 設定ファイルを反映（プロジェクト系）
  if [[ -f "$config_path" && "${1}" = "update" ]]; then
    outputStartLog "cp $config_path to $config_back_up_path"
    cp "$config_path" "$config_back_up_path"
    echo "" > "${ssh_dir}/config"
  fi

  # プロジェクト別設定ファイルを更新
  copyOfSecretFile "$common_ssh_conf_dir/$project_domain.conf" "$ssh_conf_dir/$project_domain.conf"

  # バックアップから差分を適用
  if [[ -f "$config_back_up_path" ]]; then
    patchExecute "$config_path" "$config_back_up_path" "$ssh_conf_dir"
  fi

  # 設定ファイルを反映（プロジェクト毎）
  SSHCommon::UpdateConfig "Include conf.d/\*.conf"

  # 設定ファイルを反映（共通）
  SSHCommon::UpdateConfig "Include conf.d/default-config"

  secretDirALL "$ssh_dir"

  # SSH鍵の存在チェック
  local is_ssh_exist
  local is_common_exist
  is_ssh_exist=$(findOfFileCount "$ssh_key_dir/$project_domain")
  is_common_exist=$(findOfFileCount "$common_ssh_key_dir/$project_domain")
  # SSH鍵が存在しない場合エラー終了
  if [[ "$is_ssh_exist" -eq 0 && "$is_common_exist" -eq 0 ]]; then
    outputErrorLog "You should be ssh setting"
    outputErrorLog "RUN \`localSetting init ssh all\`"
    outputErrorLog "update ssh setting $project_domain"
  fi

  # SSH鍵ファイルを更新（存在しない場合）
  if [[ "$is_ssh_exist" -eq 0 && "$is_common_exist" -ne 0 ]]; then
    copyOfSecretDir "$common_ssh_key_dir/$project_domain" "$ssh_key_dir"
  fi

  # SSH鍵ファイルをバックアップ（初回のみ）
  if [[ "$is_ssh_exist" -ne 0 && "$is_common_exist" -eq 0 ]]; then
    copyOfSecretDir "$ssh_key_dir/$project_domain" "$common_ssh_key_dir"
  fi
}

# SSH鍵を作成する
SSHCommon::CreateKey() {
  local key_dir="$1"
  local key_name="$2"

  sshCreateKey "$key_dir" "$key_name"
}

alias cleanSSHChmod='SSHCommon::CleanSSHChmod'
alias setSSHConfig='SSHCommon::SetConfig'
alias removeAllConfig='SSHCommon::ReMoveAllConfig'
alias updateSetting='SSHCommon::UpdateSetting'
alias createKey='SSHCommon::CreateKey'
