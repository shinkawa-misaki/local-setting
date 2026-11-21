namespace Array

import util/namedParameters

# リストを改行区切りで出力する
Array::List() {
  @required [string] variableName # 文字列型の variableName 引数が必須であることを宣言
  [string] separator=$'\n'        # 文字列型の separator 引数にはデフォルトで改行文字（$'\n'）を設定

  local indirectAccess="${variableName}[*]"
  (
    local IFS="$separator"
    echo "${!indirectAccess}"
  )
}