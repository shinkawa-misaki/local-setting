namespace helpers/ssh

## IMPORT ##
# ------------------------ #
import util-ume/aws
import util-ume/grep

## MAIN ##
# ------------------------ #
SSHAws::Init() {
  awsCreateSetting "default"
}

SSHAws::Update() {
  local profile_name="$1"

  awsCreateSetting "$profile_name"
}

alias sshAwsCleanUp='SSHAws::Init'
alias sshAwsUpdate='SSHAws::Update'
