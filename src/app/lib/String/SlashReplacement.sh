# "置換 → 加工 → 復元"という安全なプロセス

# エスケープ済みバックスラッシュを特殊文字列に変換している。
# 理由：Bashではバックスラッシュが入った文字列を置換すると壊れるバグが昔から報告されている為、念の為？？（私の予想）
String::ReplaceSlashes() {
  local stringToMark="$1"

  # Workaround for a Bash bug that causes string replacement to fail when a \ is in the string
  local slash="\\"
  local slashReplacement='_%SLASH%_'
  echo "${stringToMark/$slash$slash/$slashReplacement}"
}

# 先ほど仮置きした特殊文字を、本来のバックスラッシュに戻す
String::RestoreSlashes() {
  local stringToMark="$1"

  # Workaround for a Bash bug that causes string replacement to fail when a \ is in the string
  local slash="\\"
  local slashReplacement='_%SLASH%_'
  echo "${stringToMark/$slashReplacement/$slash}"
}
