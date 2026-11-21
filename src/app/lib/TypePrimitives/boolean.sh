import util/namedParameters
import util/type

# namespace oo/type
namespace TypePrimitives
### BOOLEAN

boolean.__getter__() {
  test "$this" == "${__primitive_extension_fingerprint__boolean}:true"
}

boolean.toString() {
  if [[ "$this" == "${__primitive_extension_fingerprint__boolean}:true" ]]
  then
    @return:value true
  else
    @return:value false
  fi
}

boolean.=() {
  [string] value

  if [[ "$value" == "true" ]]
  then
    this="${__primitive_extension_fingerprint__boolean}:true"
  else
    this="${__primitive_extension_fingerprint__boolean}:false"
  fi

  @return
}

Type::InitializePrimitive boolean
### /BOOLEAN

# 内部表現は一意の接頭辞＋:true または :false
# __getter__ で真偽チェック、
# toString でプレーン文字列化、
# = で代入操作、
# Type::InitializePrimitive によって型として登録
# ――という流れで、Bash における Boolean 型オブジェクトを実現
