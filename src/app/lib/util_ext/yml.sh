namespace util-ext/yml

## IMPORT ##
# ------------------------ #
import util-ext/log

## MAIN ##
# ------------------------ #
# YAML ファイルを JSON に変換して出力する関数
Yml::ToJson() {
  local yml_path="$1"

  # 指定された YAML ファイルが存在しない場合はエラーを出力する
  if [[ ! -f $yml_path ]]; then
    outputErrorLog "not found target yml:$yml_path"
  fi

  yq -o json $yml_path
}

# JSON を YAML ファイルに変換して書き込む関数
Yml::JsonToYml() {
  local json="$1"
  local yml_path="$2"

  # 指定された YAML ファイルが存在しない場合はエラーを出力する
  if [[ ! -f $yml_path ]]; then
    outputErrorLog "not found target yml:$yml_path"
  fi

  # json が空の場合は標準入力から変換する
  if [[ ${#json} -eq 0 ]]; then
    yq -P
  fi

  echo $json | yq -P > $yml_path
}

# ドット区切りのキーを yq / jq で参照できる形に変換する関数
Yml::GetKey() {
  local keys=(${1//./ })
  local key=""

  # '.' 区切りのキーをそれぞれ展開し、ハイフンを含む場合は ["key"] 形式に変換
  for index in "${!keys[@]}";
    do
      if [[ "${keys[$index]}" == *"-"* ]]; then
        key+=" | .[\"${keys[$index]}\"]"
      else
        key+=".${keys[$index]}"
      fi
    done

  echo "$key"
}

# YAML ファイル内の指定パスにあるキー情報を取得する関数
Yml::GetKeys() {
  local yml_path="$1"
  local keys="$2"
  local target="$3"

  # 指定された YAML ファイルが存在しない場合はエラーを出力する
  if [[ ! -f $yml_path ]]; then
    outputErrorLog "not found target yml:$yml_path"
  fi

  local key
  key="$(Yml::GetKey "$keys")"

  # target が空文字の場合は全てのパスを取得し、target が指定されている場合は
  # 最後の要素が target に一致するパスのみ取得する
  if [[ ${#target} -eq 0 ]]; then
    yq -o json "$yml_path" | jq -r "$key | paths | map(tostring) | join(\".\")"
  else
    yq -o json "$yml_path" | jq -r "$key | paths | select(.[-1] == \"$target\") | map(tostring) | join(\".\")"
  fi
}

# YAML ファイル内の指定パスにある値を取得する関数
Yml::GetValue() {
  local yml_path="$1"
  local keys="$2"

  # 指定された YAML ファイルが存在しない場合はエラーを出力する
  if [[ ! -f $yml_path ]]; then
    outputErrorLog "not found target yml:$yml_path"
  fi

  local key
  key="$(Yml::GetKey "$keys")"

  # $key が配列の場合はその要素をすべて展開し、配列でない場合は空文字列を返す
  yq -o json "$yml_path" | jq -r "$key | if type == \"array\" then .[] else . // \"\" end"
}

# YAML ファイル内の配列を取得し、空白で結合して文字列として返す関数
Yml::GetArrayToString() {
  local yml_path="$1"
  local keys="$2"

  # 指定された YAML ファイルが存在しない場合はエラーを出力する
  if [[ ! -f $yml_path ]]; then
    outputErrorLog "not found target yml:$yml_path"
  fi

  local key
  key="$(Yml::GetKey "$keys")"

  # null でない項目のみ処理し、配列なら要素を展開して出力、配列でなければ空文字列を返す
  yq -o json "$yml_path" | jq -r "$key | select(. != null) | if type == \"array\" then .[] else . // \"\" end" | sed 's/"//g'
}

alias ymlToJson='Yml::ToJson'
alias ymlJsonToYml='Yml::JsonToYml'
alias ymlGetKeys='Yml::GetKeys'
alias ymlGetValue='Yml::GetValue'
alias ymlGetArrayToString='Yml::GetArrayToString'
