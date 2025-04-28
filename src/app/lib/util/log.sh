import util/bash4
import UI/Color UI/Console

# ログ管理用のグローバル連想配列
declare -Ag __oo__logScopes
declare -Ag __oo__logScopeOutputs
declare -Ag __oo__logDisabledFilter
declare -Ag __oo__loggers

# 現在のスクリプトファイルに、論理的な「スコープ名」を登録
# スコープ単位でログ出力の切り替えを可能にする
Log::NameScope() {
  local scopeName="$1"
  local script="${BASH_SOURCE[1]}"
  __oo__logScopes["$script"]="$scopeName"
}

# 指定したスコープに対して、出力方法（STDERR/ファイル/etc）を追加登録
Log::AddOutput() {
  local scopeName="$1"
  local outputType="${2:-STDERR}"
  __oo__logScopeOutputs["$scopeName"]+="$outputType;"
}

# 指定スコープのログ出力設定・フィルタ設定をリセット
Log::ResetOutputsAndFilters() {
  local scopeName="$1"
  unset __oo__logScopeOutputs["$scopeName"]
  unset __oo__logDisabledFilter["$scopeName"]
}

# 全スコープのログ出力設定・フィルタ設定を完全初期化
Log::ResetAllOutputsAndFilters() {
  unset __oo__logScopeOutputs
  unset __oo__logDisabledFilter
  declare -Ag __oo__logScopeOutputs
  declare -Ag __oo__logDisabledFilter
}

# 指定スコープ/関数に対してフィルタ機能を無効化（常にログ出力）
Log::DisableFilter() {
  __oo__logDisabledFilter["$1"]=true
}

# ログ出力の本体関数
# 呼び出し元スクリプト・関数・任意subjectに応じて、
# 適切なロガー（出力方法）を選択してログを出力する。
Log() {
  local callingFunction="${FUNCNAME[1]}"
  local callingScript="${BASH_SOURCE[1]}"
  local scope
  if [[ ! -z "${__oo__logScopes["$callingScript"]}" ]]
  then
    scope="${__oo__logScopes["$callingScript"]}"
  else # just the filename without extension
    scope="${callingScript##*/}"
    scope="${scope%.*}"
  fi
  local loggerList
  local loggers
  local logger
  local logged

  if [[ ! -z "$subject" ]]
  then
    if [[ ! -z "${__oo__logScopeOutputs["$scope/$callingFunction/$subject"]}" ]]
    then
      loggerList="${__oo__logScopeOutputs["$scope/$callingFunction/$subject"]}"
    elif [[ ! -z "${__oo__logScopeOutputs["$scope/$subject"]}" ]]
    then
      loggerList="${__oo__logScopeOutputs["$scope/$subject"]}"
    elif [[ ! -z "${__oo__logScopeOutputs["$subject"]}" ]]
    then
      loggerList="${__oo__logScopeOutputs["$subject"]}"
    fi

    loggers=( ${loggerList//;/ } )
    for logger in "${loggers[@]}"
    do
      subject="${subject:-LOG}" Log::Using "$logger" "$@"
      logged=true
    done
  fi

  if [[ ! -z "${__oo__logScopeOutputs["$scope/$callingFunction"]}" ]]
  then
    if [[ -z $logged ]] || [[ ${__oo__logDisabledFilter["$scope/$callingFunction"]} == true || ${__oo__logDisabledFilter["$scope"]} == true ]]
    then
      loggerList="${__oo__logScopeOutputs["$scope/$callingFunction"]}"
      loggers=( ${loggerList//;/ } )
      for logger in "${loggers[@]}"
      do
          subject="${subject:-LOG}" Log::Using "$logger" "$@"
          logged=true
      done
    fi
  fi

  if [[ ! -z "${__oo__logScopeOutputs["$scope"]}" ]]
  then
    if [[ -z $logged ]] || [[ ${__oo__logDisabledFilter["$scope"]} == true ]]
    then
      loggerList="${__oo__logScopeOutputs["$scope"]}"
      loggers=( ${loggerList//;/ } )
      for logger in "${loggers[@]}"
      do
        subject="${subject:-LOG}" Log::Using "$logger" "$@"
      done
    fi
  fi
}

# ロガー名と、それに対応する関数を登録
Log::RegisterLogger() {
  local logger="$1"
  local method="$2"
  __oo__loggers["$logger"]="$method"
}

# ロガー名に対応する関数を呼び出し、実際にログ出力を行う
Log::Using() {
  local logger="$1"
  shift;
  if [[ ! -z ${__oo__loggers["$logger"]} ]]
  then
      ${__oo__loggers["$logger"]} "$@"
  fi
}


# DEBUGレベルのログを黄色で標準エラー出力
Logger::DEBUG() {
    Console::WriteStdErrAnnotated "${BASH_SOURCE[3]##*/}" ${BASH_LINENO[2]} $(UI.Color.Yellow) DEBUG "$@"
}

# ERRORレベルのログを赤色で標準エラー出力
Logger::ERROR() {
    Console::WriteStdErrAnnotated "${BASH_SOURCE[3]##*/}" ${BASH_LINENO[2]} $(UI.Color.Red) ERROR "$@"
}

# INFOレベルのログを青色で標準エラー出力
Logger::INFO() {
    Console::WriteStdErrAnnotated "${BASH_SOURCE[3]##*/}" ${BASH_LINENO[2]} $(UI.Color.Blue) INFO "$@"
}

# WARNレベルのログを黄色で標準エラー出力
Logger::WARN() {
    Console::WriteStdErrAnnotated "${BASH_SOURCE[3]##*/}" ${BASH_LINENO[2]} $(UI.Color.Yellow) WARN "$@"
}

# 任意のsubject名でログを出力（柔軟にカスタマイズできる）
Logger::CUSTOM() {
    Console::WriteStdErr "$(UI.Color.Yellow)[${subject^^}] $(UI.Color.Default)$* "
}

# subjectを強調し、詳細なコンテキスト付きで出力
Logger::DETAILED() {
    Console::WriteStdErrAnnotated "${BASH_SOURCE[3]##*/}" ${BASH_LINENO[2]} $(UI.Color.Yellow) "${subject^^}" "$@"
}

# すべての標準ロガー（DEBUG/ERROR/INFO等）をシステムに登録することで、Log関数から名前指定で使用できるようにしている。
Log::RegisterLogger STDERR Console::WriteStdErr
Log::RegisterLogger DEBUG Logger::DEBUG
Log::RegisterLogger ERROR Logger::ERROR
Log::RegisterLogger INFO Logger::INFO
Log::RegisterLogger WARN Logger::WARN
Log::RegisterLogger CUSTOM Logger::CUSTOM
Log::RegisterLogger DETAILED Logger::DETAILED

alias namespace='Log::NameScope'
namespace oo/log
