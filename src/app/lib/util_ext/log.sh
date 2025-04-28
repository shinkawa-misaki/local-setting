namespace util-ext

## IMPORT ##
# ------------------------ #
import util/log

## MAIN ##
# ------------------------ #
# ログメッセージを実際に出力するための関数
# 色付きでログメッセージを標準出力に出す関数
Logger::OutputMsg() {
  local script="$1"
  local lineNo=$2
  local color=$3
  local type=$4
  shift; shift; shift; shift

  echo "$color[$(date +"%Y/%m/%d %H:%M:%S")] $color[$type] $(UI.Color.Blue)[${script}:${lineNo}]$(UI.Color.Default) $* "
}

# 確認メッセージを標準エラー出力
Logger::ConfirmMsg() {
  local confirmMessage="$1"
  shift;

  Console::WriteStdErr "$(UI.Color.LightGreen)$confirmMessage $(UI.Color.Default)$* "
}

# ユーザー入力を促すメッセージを標準エラー出力
Logger::InputMsg() {
  Console::WriteStdErr "$(UI.Color.Yellow)[Please Enter] $(UI.Color.Default)$* "
}

# INFO レベルのローカルログを出力する関数
Logger::LocalINFO() {
  local output_type="$1"
  local callingScript="$2"
  local callingFunction="$3"
  local infoMessage="$4"
  local command="Console::WriteStdErrAnnotated"

  # output_type が console 以外の場合は別の出力手段を指定する
  if [[ "$output_type" != "console" ]]; then
    command="Logger::OutputMsg"
  fi

  $command "$callingScript $callingFunction" "*" "$(UI.Color.Blue)" INFO "$infoMessage"
}

# WARN レベルのローカルログを出力する関数
Logger::LocalWARNING() {
  local output_type="$1"
  local callingScript="$2"
  local callingFunction="$3"
  local warnMessage="$4"
  local command="Console::WriteStdErrAnnotated"

  # output_type が console 以外の場合は別の出力手段を指定する
  if [[ "$output_type" != "console" ]]; then
    command="Logger::OutputMsg"
  fi

  $command "$callingScript $callingFunction" "*" "$(UI.Color.LightCyan)" WARN "$warnMessage"
}

# ERROR レベルのローカルログを出力する関数
Logger::LocalERROR() {
  local output_type="$1"
  local callingScript="$2"
  local callingFunction="$3"
  local callingLineNo="$4"
  local errorMessage="$5"

  local command="Console::WriteStdErrAnnotated"

  # output_type が console 以外の場合は別の出力手段を指定する
  if [[ "$output_type" != "console" ]]; then
    command="Logger::OutputMsg"
  fi

  $command "$callingScript $callingFunction" "$callingLineNo" "$(UI.Color.Red)" ERROR "$errorMessage"
}

# INFO ログを出力するためのラッパ関数
Logger::OutputInfoLog() {
  local infoMessage="$1"
  local output_type=${2:-console}
  local bash_path=${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}
  local bash_dir="${bash_path%/*}"

  Logger::LocalINFO "$output_type" "${bash_dir##*/}/${bash_path##*/}" "${FUNCNAME[1]}" "$infoMessage"
}

# WARN ログを出力するためのラッパ関数
Logger::OutputWarnLog() {
  local warnMessage="$1"
  local output_type=${2:-console}
  local bash_path=${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}
  local bash_dir="${bash_path%/*}"

  Logger::LocalWARNING "$output_type" "${bash_dir##*/}/${bash_path##*/}" "${FUNCNAME[1]}" "$warnMessage"
}

# ERROR ログを出力し、必要に応じてスクリプトを終了する関数
Logger::OutputErrorLog() {
  local errorMessage="$1"
  local output_type=${2:-console}
  local bash_path=${3:-${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}}
  local bash_dir="${4:-${bash_path%/*}}"
  local function_name="${5:-${FUNCNAME[1]}}"

  Logger::LocalERROR "$output_type" "${bash_dir##*/}/${bash_path##*/}" "$function_name" "${BASH_LINENO[2]}" "$errorMessage"

  # output_type が console の場合のみスクリプトを終了
  if [[ "$output_type" == "console" ]]; then
    exit 1
  fi
}

# 処理開始時のログを出力する関数
Logger::OutputStartLog() {
  local logMessage="$1"
  local output_type=${2:-console}
  local bash_path=${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}
  local bash_dir="${bash_path%/*}"

  # logMessage が空の場合は呼び出し元関数名を使用
  if [[ ${#logMessage} -eq 0 ]]; then
      logMessage=${FUNCNAME[1]}
  fi

  Logger::LocalINFO "$output_type" "${bash_dir##*/}/${bash_path##*/}" "${FUNCNAME[1]}" "START $logMessage"
}

# 処理結果をログに出力する関数
Logger::OutputResultLog() {
  local result="$1"
  local output_type="$2"

  # output_type が console/file 以外の場合は console に変更
  if [[ "$output_type" != "console" && "$output_type" != "file" ]];then
    shift;
    output_type="console"
  else
    shift;shift;
  fi

  local logMessage="${*:-${FUNCNAME[1]}}"
  local bash_path=${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}
  local bash_dir="${bash_path%/*}"

  # result が 0 の場合は成功ログ、それ以外はエラーログ
  if [[ "$result" == "0" ]]; then
    Logger::LocalINFO "$output_type" "${bash_dir##*/}/${bash_path##*/}" "${FUNCNAME[1]}" "END $logMessage Success"
  else
    Logger::OutputErrorLog "$logMessage is Failed" "$output_type" "$output_type" "$bash_path" "$bash_dir" "${FUNCNAME[1]}"
  fi
}

alias confirmMsg='Logger::ConfirmMsg'
alias inputMsg='Logger::InputMsg'
alias outputInfoLog='Logger::OutputInfoLog'
alias outputWarnLog='Logger::OutputWarnLog'
alias outputErrorLog='Logger::OutputErrorLog'
alias outputStartLog='Logger::OutputStartLog'
alias outputResultLog='Logger::OutputResultLog'
