namespace helpers/ssh

## IMPORT ##
# ------------------------ #
import util_ext/aws
import util_ext/grep

## MAIN ##
# ------------------------ #
# AWS 用の SSH 設定を“初期化”または“リセット”するメソッド
SSHAws::Init() {
  awsCreateSetting "default"
}

# 任意の AWS プロファイルに対して SSH 設定を“更新”するメソッド
SSHAws::Update() {
  local profile_name="$1"

  awsCreateSetting "$profile_name"
}

alias sshAwsCleanUp='SSHAws::Init'
alias sshAwsUpdate='SSHAws::Update'
