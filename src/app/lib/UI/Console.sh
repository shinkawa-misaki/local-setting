namespace UI
import UI/Color

# 標準エラー出力へメッセージを出すシンプルなユーティリティ
# あくまでエラーや警告などを stderr に送る
# 改行や特殊文字を崩さず、安全に stderr へ文字を送ることが可能
Console::WriteStdErr() {
  # http://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
  cat <<< "$(printf "$*")" 1>&2
  return
}

# いつ・どこで・何の種類のメッセージかを一行に詰め込んだ、アノテーション付きのエラー出力関数
Console::WriteStdErrAnnotated() {
  local script="$1"
  local lineNo=$2
  local color=$3
  local type=$4
  shift; shift; shift; shift

  Console::WriteStdErr "$color[$(date +"%Y/%m/%d %H:%M:%S")] $color[$type] $(UI.Color.Blue)[${script}:${lineNo}]$(UI.Color.Default) $* "
}
