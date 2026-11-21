namespace helpers
set -e

## IMPORT ##
# 必要なユーティリティを読み込む
# ------------------------ #
import util/class
import util_ext/log
import util_ext/aws
import util_ext/date
import util_ext/json
import helpers/config
import util_ext/providers

## MAIN ##
# ------------------------ #
# 環境変数を操作するクラス
class:EnvCommon() {
  private string project_domain
  private string project_dir
  private string resource_dir
  private string env_dir
  private string env_path
  private string env_example_path
  private string env_testing_path
  private string config_path
  private string aws_env_secret_path
  private string aws_setting  # <- 宣言のみで代入なしなので宣言ミス？？
  private Config env_config
  private Config databse_config

  # コンストラクタ
  EnvCommon.__constructor__() {
    this project_domain = "$1"
    this project_dir = "$2"
    this resource_dir = "$3"
    this config_path = "$4"

    this env_config __constructor__ "$(this config_path)" ".env"
    this databse_config __constructor__ "$(this config_path)" ".database"

    this env_dir = "$(this project_dir)$(this env_config Get "dir")"
    this aws_env_secret_path = "$(this resource_dir)/aws_env_secret.json"
    this env_example_path = "$(this env_dir)/.env.example"
    this env_path = "$(this env_dir)/.env"
    this env_testing_path = "$(this env_path).testing"
  }

  # デフォルト環境変数設定を適用する
  EnvCommon.SettingDefault() {
    # .env.exampleが存在しない場合はエラー終了
    if [[ ! -f $(this env_example_path) ]]; then
      outputErrorLog "must be $(this env_example_path) exist !!!" && exit 1
    fi
    cp "$(this env_example_path)" "$(this env_path)"

    # AWSの環境変数を設定
    this SetKeyValueOfAws

    # ローカル設定値を環境変数として設定
    this SetKeyValueOfConfig
    this SettingDBWithTarget
  }

  # テスト用環境変数の設定を適用する
  EnvCommon.SettingTesting() {
    local env_testing_keys=( $(this env_config GetKeys "key_value.testing") )

    # テスト環境変数が存在する場合のみ処理を実行
    if [[ "${#env_testing_keys[@]}" -gt 0 ]]; then
      if [[ ! -e "$(this env_testing_path)" ]]; then
        touch "$(this env_testing_path)"
        echo "APP_ENV=testing" >> "$(this env_testing_path)"
        echo "APP_KEY=" >> "$(this env_testing_path)"
      fi

      for key in "${env_testing_keys[@]}";do
        local value
        local log_message
        value="$(this env_config Get "key_value.testing.$key")"
        log_message="env.testing setting $(this project_domain) $key"

        gsAddUniqueRow "$key=$value" "$(this env_testing_path)" "" "$log_message"
      done
    fi
  }

  # 指定環境の設定ファイルにあるキーと値を設定する
  EnvCommon.SetKeyValueOfConfig() {
    local env_target=${1:-local}
    local env_key_list=( $(this GetEnvKeyList) )
    local local_key_list=( $(this env_config Get "key_value.${env_target}") )

    for index in "${!env_key_list[@]}"; do
      local key=${env_key_list[$index]}
      local value
      value=$(this env_config Get "key_value.${env_target}.$key")
      unset local_key_list[$key]

      if [[ -n "$value" ]]; then
        this SetKeyValue "$key" "$value"
        unset env_key_list[$index]
      fi

      # 全てのキーを処理したら終了
      if [[ ${#local_key_list[@]} -eq 0 ]]; then
        break
      fi
    done
    outputResultLog $? "env setting $(this project_domain)"
  }

  # 指定DB環境の値を環境変数に設定する
  EnvCommon.SettingDBWithTarget() {
    local env_key_list=( $(this GetEnvKeyList) )
    local env_target=${1:-default}
    local host_key_list=( $(this env_config Get "database.local_key.host") )
    local user_key_list=( $(this env_config Get "database.local_key.user") )
    local password_key_list=( $(this env_config Get "database.local_key.password") )
    local total_count=$((( ${#host_key_list[@]} + ${#user_key_list[@]} + ${#password_key_list[@]} )))

    local count=0
    for index in "${!env_key_list[@]}"; do
      local key="${env_key_list[$index]}"

      local value
      if printf '%s\n' "${host_key_list[@]}" | grep -qx "$key"; then
        value=$(this databse_config Get "${env_target}.host")
      elif printf '%s\n' "${user_key_list[@]}" | grep -qx "$key"; then
        value=$(this databse_config Get "${env_target}.root.user")
      elif printf '%s\n' "${password_key_list[@]}" | grep -qx "$key"; then
        value=$(this databse_config Get "${env_target}.root.password")
        # DBパスワードが空の場合はユーザ入力を要求
        if [[ -z "$value" ]]; then
          inputMsg "${env_target} DB PASSWORD:"
          read -r value
        fi
      else
        continue
      fi

      if [[ -n "$value" ]]; then
        this SetKeyValue "$key" "$value" && (( count++ ))
      fi

      # 全てのキーを処理したら終了
      if [[ $count -eq $total_count ]]; then
        break
      fi
    done
    outputResultLog $? "env setting $(this project_domain)"
  }

  # AWSから取得した値を環境変数に設定する
  EnvCommon.SetKeyValueOfAws() {
    local env_target=${1:-local}
    local env_key_list=( $(this GetEnvKeyList) )
    local aws_profiles=( $(this env_config GetKeys "aws" 2> /dev/null))

    for aws_profile_key in "${aws_profiles[@]}"; do
      case $(this env_config Get "aws.${aws_profile_key}.secret_type") in
        "file") this SourceOfFile "$aws_profile_key";; # AWSからファイル形式で取得
             *) this SourceOfJson "$aws_profile_key";; # AWSからJSON形式で取得
      esac

      local env_key="aws.${aws_profile_key}.${env_target}.key_prefix"
      local allow_key_prefix_list=( $(this env_config GetArrayToString "$env_key") )

      for index in "${!env_key_list[@]}"; do
        local key=${env_key_list[$index]}
        local key_prefix=${key%%_*}
        if printf '%s\n' "${allow_key_prefix_list[@]}" | grep -q "${key_prefix}"; then
          local value
          value=$(jsonGetValue "$(this aws_env_secret_path)" ".$key")
          if [[ -n "$value" ]]; then
            this SetKeyValue "$key" "$value"
            unset env_key_list[$index]
          fi
        fi
      done
    done
  }

  # 指定したキーと値を.envファイルに設定する
  EnvCommon.SetKeyValue() {
    local key="$1"
    local value="$2"

    gsReplaceOFRegExpFirst "$key=.*$" "$key=$value" "$(this env_path)"
    outputResultLog $? "env setting $(this project_domain) $key"
  }

  # .envファイルから環境変数のキーリストを取得する
  EnvCommon.GetEnvKeyList(){
    less "$(this env_path)" | gsed -re "/(^#|^$)/d; s/(export |\\')//g; s/$/\"/g; s/=.*$//g;"
  }

  # AWSシークレット情報をJSON形式で取得
  EnvCommon.SourceOfJson() {
    this AwsOutPutSecret "$1"
  }

  # AWSシークレット情報をファイル形式で取得・加工
  EnvCommon.SourceOfFile() {
    local aws_profile_key="$1"
    local tmp_file_path
    tmp_file_path=$(this aws_env_secret_path | gsed -e 's/\./_env_tmp\./')

    this AwsOutPutSecret "$aws_profile_key"

    # JSONをエスケープ後、指定パスに保存
    (gsEscapeJson "$(this aws_env_secret_path)" | jq -r .) > "$tmp_file_path" && mv "$tmp_file_path" "$(this aws_env_secret_path)"
  }

  # AWSシークレットを取得して指定パスに保存
  EnvCommon.AwsOutPutSecret() {
    local aws_profile_key="$1"
    local aws_profile
    local aws_secret_id
    aws_profile=$(echo "$aws_profile_key" | gsed 's/_/-/')
    aws_secret_id="$(this env_config Get "aws.${aws_profile_key}.secret_id")"

    # ファイルがない場合や更新日が古い場合のみAWSから取得
    if [[ ! -f "$(this aws_env_secret_path)" || "$(dateFileUpdated "$(this aws_env_secret_path)")" != "$(dateToday)" ]]; then
      awsOutPutSecret "$aws_profile" "$aws_secret_id" "$(this aws_env_secret_path)"
      outputResultLog $? "download aws env secret info"
    fi
  }
}

Type::Initialize EnvCommon
