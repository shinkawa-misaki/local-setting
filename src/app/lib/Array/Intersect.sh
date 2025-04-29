namespace Array

import util/namedParameters
import util/type

Array::Intersect() {
  @required [array] arrayA
  @required [array] arrayB

  array intersection


  #arrayA に存在し、かつ arrayB には存在しない要素の集合が得られる
  # http://stackoverflow.com/questions/2312762/compare-difference-of-two-arrays-in-bash
  for i in "${arrayA[@]}"
  do
    local skip=
    for j in "${arrayB[@]}"
    do
      [[ "$i" == "$j" ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || intersection+=("$i")
  done

  # 名前付き引数フレームワークの機能で、最終的に、intersection 配列を帯び出し元へ返す。
  @get intersection
}
