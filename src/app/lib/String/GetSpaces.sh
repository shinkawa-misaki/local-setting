# 指定した個数だけ空白文字を出力する
String::GetSpaces() {
  local howMany="$1"

  # もしも 0より大きい数が渡された場合だけ、処理を進める
  if [[ "$howMany" -gt 0 ]]
  then
    ( printf "%*s" "$howMany" )　# 幅を howMany に合わせて、空白埋めの文字列を出力する
  fi
}
