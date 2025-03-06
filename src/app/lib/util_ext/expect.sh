namespace util-ume/expect

## IMPORT ##
# ------------------------ #
import util-ume/log
import util-ume/providers

## MAIN ##
# ------------------------ #
# 受け取った expect スクリプトを実行する関数
Expect::Command() {
  local expectCommand="$1"
  shift;

  expect -c "$expectCommand ; $@"
}

# SSH 鍵生成を自動化するための関数
Expect::KeyGenCommand() {
  local key_path="$1"
  local time_out="${2:-10}"
  local ssh_command="spawn ssh-keygen -t rsa -C $project_domain -b 4096 -f $key_path"
  local args=(
    "expect -re \"(Overwrite)?\" ;"
    "send \"y\r\" ;"
    "expect passphrase ;"
    "send \"${PASS_PHRASE}\\r\" ;"
    "expect \" (empty for no passphrase): \" ;"
    "expect passphrase ;"
    "send \"${PASS_PHRASE}\\r\" ;"
    "expect \\$ ;"
    "exit ;"
  )

  Expect::Command "set timeout $time_out; $ssh_command" "${args[*]}"
}

# ssh-add を自動化するための関数
Expect::SSHADDCommand() {
  local key_path="$1"
  local time_out="${2:-3}"
  local ssh_command="spawn ssh-add $key_path"
  local args=(
    "expect passphrase ;"
    "send \"${PASS_PHRASE}\\r\" ;"
    "expect \\$ ;"
    "exit ;"
  )

  Expect::Command "set timeout $time_out; $ssh_command" "${args[*]}"
}

# SSH 接続時のパスワード入力や fingerprint 確認を自動化する関数
Expect::SSHCommand() {
  local ssh_command="${1}"
  local ssh_pass="$2"
  local time_out="${3:-3}"

  local result
  result="$(expect -c "
    log_user 0
    set timeout ${time_out}
    spawn ${ssh_command}
    expect {
        -glob \"fingerprint\" {
            send \"yes\\r\"
            exp_continue
        }
        -glob \"password:\" {
            send -- \"${ssh_pass}\\r\"
            exp_continue
        }
        -glob \"passphrase\" {
            send -- \"$PASS_PHRASE\\r\"
            exp_continue
        }
        -glob \"denied\" {
            send_user 1
            exit
        }
        timeout {
            send_user 3
            exit
        }
        eof {
            catch wait result
            set exit_code [lindex \$result 3]
            send_user \$exit_code
            exit
        }
    }"
  )"

  echo "$result"
}

alias exKeygen='Expect::KeyGenCommand'
alias exSSHAdd='Expect::SSHADDCommand'
alias exSSHCommand='Expect::SSHCommand'
