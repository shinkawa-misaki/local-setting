namespace Array

Array::Contains() {
  local element
  for element in "${@:2}" # 第2引数以降（検索対象の配列）をループ
  do
    [[ "$element" = "$1" ]] && return 0 # 見つかったら成功(0)を返す
  done
  return 1 # 見つからなければ失敗(1)を返す
}
