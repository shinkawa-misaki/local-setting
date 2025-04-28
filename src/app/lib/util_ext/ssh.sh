namespace util-ext

## IMPORT ##
# ------------------------ #
import util/type
import util-ext/expect
import util-ext/log

## MAIN ##
# ------------------------ #
# SSH 鍵を生成する関数
SSH::CreateKey() {
  local key_path="$1"

  exKeygen "$key_path"
}

# SSH 接続を用いてコマンドを実行する関数
SSH::Command() {
  local ldap_command="$1"

  outputStartLog "ssh -T $host $ldap_command"
  local result
  result=$(exSSHCommand "ssh -T $host $ldap_command" "$ldap_pass")
  outputResultLog "$result" "ssh -T $host $ldap_command"
  # コマンド実行が失敗した場合は終了する
  if [[ "$result" != "0" ]]; then
    echo "$result"
  fi
}

# scp コマンドを実行し、ファイルを転送する関数
SSH::ScpCommand() {
  local local_dir="$1"
  local remote_dir="$2"
  local options="$3"

  outputStartLog "scp $options $local_dir $remote_dir"
  local result
  result=$(exSSHCommand "scp $options $local_dir $remote_dir" "$ldap_pass")
  outputResultLog "$result" "scp $options $local_dir $remote_dir"
  # 転送が失敗した場合は終了する
  if [[ "$result" != "0" ]]; then
    exit 1
  fi
}

# SSH 接続を試行し、接続可否を確認する関数
SSH::ConnectionCheck() {
  outputInfoLog "$host is connection check start"
  local result
  result="$(exSSHCommand "ssh -T $host exit;" "$ldap_pass")"

  # 成功した場合は成功メッセージを出力、失敗した場合はエラーとともに終了
  if [[ "$result" == "0" ]]; then
    outputInfoLog "$host is connection success!"
  else
    outputResultLog "$result" "$host is connection failed"
    echo "$result"
  fi
}

alias sshCreateKey='SSH::CreateKey'
alias sshCommand='SSH::Command'
alias sshScpCommand='SSH::ScpCommand'
alias sshConnectionCheck='SSH::ConnectionCheck'
