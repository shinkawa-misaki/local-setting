namespace util_ext

## IMPORT ##
# ------------------------ #
import util_ext/log
import util_ext/gsed       # 正規表現＆文字列操作
import util_ext/json
import util_ext/chmod
import util_ext/expect
import util_ext/providers

## MAIN ##
# ------------------------ #
# AWS の設定ファイル（config/credentials）を作成、更新するメイン処理
AWS::CreateSetting() {
  local profile="$1"
  local region="${2:-"ap-northeast-1"}"
  local aws_dir="$HOME/.aws"
  local aws_config_path="${aws_dir}/config"
  local aws_credentials_path="${aws_dir}/credentials"

  # $aws_dir が存在しない場合に新規ディレクトリを作成する
  if [[ ! -d "$aws_dir" ]]; then
    mkdir "$aws_dir"
  fi

  # $aws_config_path が存在しない場合に新規ファイルを作成する
  if [[ ! -f "$aws_config_path" ]]; then
    touch "$aws_config_path"
  fi

  # $aws_credentials_path が存在しない場合に新規ファイルを作成する
  if [[ ! -f "$aws_credentials_path" ]]; then
    touch "$aws_credentials_path"
  fi

  # profile が空文字の場合は default に切り替える
  if [[ -z "$profile" ]]; then
    profile="default"
  fi

  publicDirALL "$aws_dir"
  # aws configure list の結果が 0 であれば指定した profile は存在する
  if aws configure list --profile "$profile" >/dev/null 2>&1; then
    confirmMsg "aws config の $profile が下記の内容で設定されています。"
    AWS::GetConfigureValues "$profile"
    inputMsg "aws config の $profile 設定を変更しますか？(y/n)"
    read -r answer
    # answer が "y" または "Y" の場合のみ設定を更新する
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      AWS::UpdateSetting "$profile" "$region"
    fi
  else
    AWS::UpdateSetting "$profile" "$region"
  fi
  secretDirALL "$aws_dir"
}

# AWS の設定を更新するための関数　:プロファイルとリージョンを書き込む
AWS::UpdateSetting() {
  local profile="$1"
  local region="${2:-"ap-northeast-1"}"

  outputStartLog "setting aws $profile"
  aws configure set region "$region" &&
  aws configure --profile "$profile"
  outputResultLog $? "setting aws $profile"
}

# AWS の設定値を表示するための関数
AWS::GetConfigureValues() {
  local profile="$1"

  aws configure list --profile "$profile" --output text 2>/dev/null | \
    awk '{printf "%-12s: %s\n", $1, $2}'
}

# AWS Secrets Manager からシークレットを取得し、出力ファイルに書き込む関数
AWS::OutPutSecret() {
  local profile="$1"
  local secret_id="$2"
  local output_path="$3"
  local target_path="${3/\./_tmp.}"
  local default_option="--output=json"
  local option="${4:-${default_option}}"

  # secret_id の文字数が 0 の場合はエラーを出力する
  if [[ "${#secret_id}" -eq 0 ]]; then
    outputErrorLog "please set secret_id !!!"
  fi

  # $output_path が存在しない場合は新規ファイルを作成する
  if [[ ! -f $output_path ]]; then
    touch "$output_path"
  fi

  aws secretsmanager get-secret-value \
   --secret-id="$secret_id" $option \
   --profile="$profile" > "$target_path"

  jsonGetValue "$target_path" ".SecretString" > "$output_path"
  rm "$target_path"
}

# AWS S3 バケットからファイルを取得する関数
AWS::GetS3Bucket() {
  local remote_url="$1"
  local local_dir="$2"
  local profile="${3:-defaul}"

  # remote_url が指定されていない場合はエラーを出力する
  if [[ ${#remote_url} -eq 0 ]]; then
    outputErrorLog "please set S3 bucket url !!!"
  fi

  aws s3 cp "$remote_url" "$local_dir" --profile="$profile" 1>&2
}

# AWS ECR のログインパスワードを取得する関数
AWS::GetEcrGetPassword() {
  local profile="${1:-default}"

  aws ecr get-login-password --profile "$profile"
}

alias awsCreateSetting='AWS::CreateSetting'
alias awsOutPutSecret='AWS::OutPutSecret'
alias awsGetS3Bucket='AWS::GetS3Bucket'
alias awsGetEcrGetPassword='AWS::GetEcrGetPassword'
