namespace util

# no dependencies

# どんな「コマンド」かを返すラベル付け関数
Command::GetType() {
  local name="$1"
  local typeMatch=$(type -t "$name" 2> /dev/null || true)
  echo "$typeMatch"
}

# alias,function,builtin、いずれかであれば「コマンドとして存在する」と判断する命令
Command::Exists(){
  local name="$1"
  local typeMatch=$(Command::GetType "$name")
  [[ "$typeMatch" == "alias" || "$typeMatch" == "function" || "$typeMatch" == "builtin" ]]
}

# aliasかどうかをチェックする命令
Alias::Exists(){
  local name="$1"
  local typeMatch=$(Command::GetType "$name")
  [[ "$typeMatch" == "alias" ]]
}

# 関数として定義されているか調べる命令
Function::Exists(){
  local name="$1"
  declare -f "$name" &> /dev/null
}

# 特定の文字列で始まる関数名を片っ端から列挙する命令
Function::GetAllStartingWith() {
  local startsWith="$1"
  compgen -A 'function' "$startsWith" || true
}

# 関数の実行前後に任意のコードを動的に注入する命令
Function::InjectCode() {
  local functionName="$1"
  local injectBefore="$2"
  local injectAfter="$3"
  local body=$(declare -f "$functionName")
  body="${body#*{}" # trim start
  body="${body%\}}" # trim end
  local enter=$'\n'
  eval "${functionName}() { ${enter}${injectBefore}${body}${injectAfter}${enter} }"
}
