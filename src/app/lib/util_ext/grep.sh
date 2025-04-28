namespace util-ext

## IMPORT ##
# ------------------------ #
import util-ext/log
import util-ext/gsed　# 正規表現エスケープ用の gsed を利用

## MAIN ##
# ------------------------ #
# 指定された文字列に対して、検索ワードが先頭/末尾/部分一致するかを調べる関数
Grep::OfWord() {
    # grep -E -c "^search_word"   → 厳密に「先頭一致」を数える
    # grep -E -c "search_word$"   → 厳密に「末尾一致」を数える
    # grep -E -c "search_word"    → 部分一致を数える
  local target_word="$1"
  local search_word="$2"
  local option="$3"

  # target_word もしくは search_word が空の場合はエラーを出力する
  if [[ ${#target_word} -eq 0 ]] || [[ ${#search_word} -eq 0 ]]; then
    outputErrorLog "target_word or search_word must be length over 1"
  fi

  # 特殊文字をエスケープ
  search_word=$(gsEscapeRegex "$search_word")

  case $option in
    "^") echo "$target_word" | grep -E -c "^${search_word}" || [[ $? == 1 ]];;　
    "$") echo "$target_word" | grep -E -c "${search_word}$" || [[ $? == 1 ]];;
      *) echo "$target_word" | grep -E -c "${search_word}"  || [[ $? == 1 ]];;
  esac
}

# 複数の単語配列に対して、検索ワードが一致する数を調べる関数
Grep::OfWords() {
  local search_word="$1"
  shift;
  local target_words=( ${*} )

  # target_words もしくは search_word が空の場合はエラーを出力する
  if [[ ${#target_words[@]} -eq 0 ]] || [[ ${#search_word} -eq 0 ]]; then
    outputErrorLog "target_word or search_word must be length over 1"
  fi

  # 特殊文字をエスケープ
  search_word=$(gsEscapeRegex "$search_word")

  echo "${target_words[@]}" | tr ' ' '\n' | grep -E -c "${search_word}" || [[ $? == 1 ]]
}

# 指定ファイルから検索ワードの一致数を調べる関数
Grep::OfFile() {
    # less "$target_file" | grep -c "^search_word/\\n/"  → 行頭一致
    # less "$target_file" | grep -c "search_word/\\n/$"  → 行末一致
    # less "$target_file" | grep -c "search_word/\\n/"   → 部分一致
  local search_word="$1"
  local target_file="$2"
  local option="${3:-"*"}"

  # search_word が空の場合はエラーを出力する
  if [[ ${#search_word} -eq 0 ]]; then
    outputErrorLog "search_word must be length over 1"
  fi

  # target_file が存在しない場合はエラーを出力する
  if [[ ! -f $target_file ]]; then
    outputErrorLog "not found target_file:$target_file"
  fi

  # 特殊文字をエスケープ
  search_word=$(gsEscapeRegex "${search_word/\//\\/}")

  case ${option} in
    "^") (less "$target_file" | grep -c "^${search_word/\\n/}") || [[ $? == 1 ]];;
    "$") (less "$target_file" | grep -c "${search_word/\\n/}$") || [[ $? == 1 ]];;
      *) (less "$target_file" | grep -c "${search_word/\\n/}")  || [[ $? == 1 ]];;
  esac
}

# 指定ファイルに対し、複数行で検索を行い、特定パターンが継続的にマッチするか判定する関数
Grep::OfFileOFRows() {
  local words=( $(echo "${1}" | gsed -re 's/ /\\\s/g; s/\\n/ /g; s/(\[|\]|\(|\))//g; /^$/d') )
  local target_file="$2"
  local space_cnt
  space_cnt=$(echo "${words[@]}" | grep -c " " || [[ $? == 1 ]])
  local target_rows=$((${#words[@]} - space_cnt - 1))
  local is_exit
  # 最初のキーワードが末尾に含まれる行を検索
  is_exit=$(less "$target_file" | grep -E -c "${words[0]}$") || [[ $? == 1 ]]

  # words 配列が空の場合はエラーを出力する
  if [[ "${#words[@]}" -eq 0 ]]; then
    outputErrorLog "word must be length over 1"
  fi

  # target_file が存在しない場合はエラーを出力する
  if [[ ! -f $target_file ]]; then
    outputErrorLog "not found target_file:$target_file"
  fi

  # 複数行継続してマッチするかを確認する
  for index in "${!words[@]}"
  do
    is_exit=$(less "$target_file" | grep -A $target_rows "${words[0]}" | grep -E -c "${words[$index]}$") || [[ $? == 1 ]]

    # 途中でマッチしなくなった場合はループを抜ける
    if [[ $is_exit -eq 0 ]]; then
      break
    fi
  done

  echo "$is_exit"
}

alias grepOfWord='Grep::OfWord'
alias grepOfWords='Grep::OfWords'
alias grepOfFile='Grep::OfFile'
alias grepOfFileRows='Grep::OfFileOFRows'
