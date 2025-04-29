namespace helpers
set -e

## IMPORT ##
# ------------------------ #
import util/class
import util_ext/log
import util_ext/yml
import util_ext/grep
import helpers/config
import util_ext/providers

## MAIN ##
# ------------------------ #
# YML設定操作クラス
class::YmlCommon() {
  private string project_name
  private string project_dir
  private string yml_dir
  private string yml_path
  private string config_path
  private Config yml_config
  private Config databse_config

  # コンストラクタ
  YmlCommon.__constructor__() {
    this project_name = "$1"
    this project_dir = "$2"
    this config_path = "$(configDir)/$(this project_name).json"

    this yml_config __constructor__ "$(this config_path)" ".yml"
    this databse_config __constructor__ "$(this config_path)" ".database"

    this yml_dir = "$(this project_dir)$(this yml_config Get "dir")"
  }

  # デフォルトのYML設定を適用する
  YmlCommon.SettingDefault() {
    local yml_path_list=( $(this yml_config GetKeys "path") )

    for target in "${!yml_path_list[@]}"; do
      outputStartLog "yml_path; $(this yml_config Get "path.${target}"
      this yml_path = "$(this yml_dir)/$(this yml_config Get "path.${target}")"
      outputResultLog $? "yml_path; $(this yml_config Get "path.${target}"
      # ローカル設定値をYMLに設定
      this SetKeyValueOfConfig "$target"
    done

    # DB関連のデフォルト設定を適用
    this SettingDBWithTarget
  }

  # 指定された設定ファイルからYMLのキーと値を設定する
  YmlCommon.SetKeyValueOfConfig() {
    local yml_target="$1"
    local setting_target="${2:-default}"
    local yml_key_list=( $(ymlGetKeys "$(this yml_path)") )
    local local_key_list=( $(this yml_config Get "key_value.${yml_target}.${setting_target}" 2> /dev/null) )
    local json
    json="$(ymlToJson "$(this yml_path)")"

    for index in "${!yml_key_list[@]}"; do
      local key=${yml_key_list[$index]}
      local value
      value=$(this yml_config Get "key_value.$yml_target.$key" 2> /dev/null)
      unset local_key_list[$key]

      if [[ -n "$value" ]]; then
        json="$(this SetKeyValue "$key" "$value" "$json")"
        unset yml_key_list[$index]
      fi

      # 全てのキーを処理したら終了
      if [[ ${#local_key_list[@]} -eq 0 ]]; then
        break
      fi
    done
    ymlJsonToYml "$json" "$(this yml_path)"
    outputResultLog $? "yml setting $(this project_name)"
  }

  # 指定DB設定をYMLに適用する
  YmlCommon.SettingDBWithTarget() {
    this yml_path = "$(this yml_dir)/$(this yml_config Get "database.path")"
    local yml_target=${1:-default}
    local yml_key_list=( $(ymlGetKeys "$(this yml_path)") )
    local host_key_list=( $(this yml_config Get "database.local_key.host") )
    local user_key_list=( $(this yml_config Get "database.local_key.user") )
    local password_key_list=( $(this yml_config Get "database.local_key.password") )
    local total_count=$((( ${#host_key_list[@]} + ${#user_key_list[@]} + ${#password_key_list[@]} )))

    local json
    json="$(ymlToJson "$(this yml_path)")"

    local count=0
    for index in "${!yml_key_list[@]}"; do
      local key="${yml_key_list[$index]}"

      local value
      if printf '%s\n' "${host_key_list[@]}" | grep -qx "$key"; then
        value=$(this databse_config Get "${yml_target}.host")
      elif printf '%s\n' "${user_key_list[@]}" | grep -qx "$key"; then
        value=$(this databse_config Get "${yml_target}.user")
      elif printf '%s\n' "${password_key_list[@]}" | grep -qx "$key"; then
        value=$(this databse_config Get "${yml_target}.password")
        # DBパスワードが空の場合、ユーザから入力を受け取る
        if [[ -z "$value" ]]; then
          inputMsg "${yml_target} DB PASSWORD:"
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
    ymlJsonToYml "$json" "$(this yml_path)"
    outputResultLog $? "yml setting $(this project_name)"
  }

  # YMLファイルの指定キーに値を設定する
  YmlCommon.SetKeyValue() {
    local key="$1"
    local value="$2"
    local json="$3"

    outputStartLog "yml setting $(this project_name) $key"
    echo "$json" | jsonReplace "$key" "$value"
    outputResultLog $? "yml setting $(this project_name) $key"
  }
}

# クラスを有効化
Type::Initialize YmlCommon
