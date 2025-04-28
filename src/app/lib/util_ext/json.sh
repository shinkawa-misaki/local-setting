namespace util-ext

## IMPORT ##
# ------------------------ #
import util-ext/log

## MAIN ##
# ------------------------ #
# ドット区切りのキー指定を jq でアクセスできる形に変換する関数
Json::GetKey() {
  local keys=( ${1//./ } )
  local key=""

  # '.' 区切りのキーをそれぞれ展開し、ハイフンを含む場合は ["key"] 形式に変換
  for index in "${!keys[@]}"; do
    if [[ "${keys[$index]}" == *"-"* ]]; then
      key+=" | .[\"${keys[$index]}\"]"
    else
      key+=".${keys[$index]}"
    fi
  done

  echo "$key"
}

# JSON ファイル内の指定キーを新しい値に置換する関数
Json::Replace() {
  local keys="$1"
  local value="$2"

  # $json_path が存在しない場合はエラーを出力する
  if [[ ! -f $json_path ]]; then
    outputErrorLog "not found target json:$json_path"
  fi

  local key
  key="$(Json::GetKey "$keys")"

  jq "$key|=\"$value\""
}

# JSON ファイル内の指定オブジェクト配下のキーを取得する関数
Json::GetKeys() {
  local json_path="$1"
  local keys="$2"

  # $json_path が存在しない場合はエラーを出力する
  if [[ ! -f $json_path ]]; then
    outputErrorLog "not found target json:$json_path"
  fi

  local key
  key="$(Json::GetKey "$keys")"

  jq -r "${key}? | keys[]?" "$json_path"
}

# JSON ファイル内の指定キーの値を取得する関数 (配列の場合は全要素を出力)
Json::GetValue() {
  local json_path="$1"
  local keys="$2"

  # $json_path が存在しない場合はエラーを出力する
  if [[ ! -f $json_path ]]; then
    outputErrorLog "not found target json:$json_path"
  fi

  local key
  key="$(Json::GetKey "$keys")"

  # $key が配列の場合はその要素をすべて展開し、配列でない場合は空文字列を返す
  jq -r "$key | if type == \"array\" then .[] else . // \"\" end" "$json_path"
}

# JSON ファイル内の指定キーの配列を文字列として取得する関数
Json::GetArrayToString() {
  local json_path="$1"
  local keys="$2"

  # $json_path が存在しない場合はエラーを出力する
  if [[ ! -f $json_path ]]; then
    outputErrorLog "not found target json:$json_path"
  fi

  local key
  key="$(Json::GetKey "$keys")"

  # null でない項目のみ処理し、配列なら要素を展開して出力、配列でなければ空文字列を返す
  jq -r "$key | select(. != null) | if type == \"array\" then .[] else . // \"\" end" "$json_path" | sed 's/"//g'
}

alias jsonReplace='Json::Replace'
alias jsonGetKeys='Json::GetKeys'
alias jsonGetValue='Json::GetValue'
alias jsonGetArrayToString='Json::GetArrayToString'
