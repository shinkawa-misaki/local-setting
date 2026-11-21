import util/namedParameters
import util/type

# namespace oo/type
namespace TypePrimitives
## Awaiting pull requests for this one!

# 整数オブジェクトへの代入メソッド
integer.=() {
  [string] value

  this="$value"

  @return
}

Type::InitializePrimitive integer
