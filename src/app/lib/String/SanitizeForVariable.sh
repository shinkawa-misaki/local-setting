# 英数字以外」 を アンダースコア（_）に変換する
String::SanitizeForVariableName() {
  local type="$1"
  echo "${type//[^a-zA-Z0-9]/_}"　# Bash のパターン置換機能
}
