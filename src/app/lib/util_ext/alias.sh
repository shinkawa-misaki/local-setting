namespace util-ume

## IMPORT ##
# ------------------------ #
import util-ume/log
import util-ume/grep
import util-ume/gsed
import util-ume/providers

## MAIN ##
# ------------------------ #
# alias ファイルが存在しない場合に作成する関数
Alias::Init() {
  # $alias_path が存在しない場合に新規ファイルを作成する
  if [[ ! -e $alias_path ]]; then
    outputInfoLog "touch $alias_path"
    touch "$alias_path"
  fi
}

# alias ファイルに新規ワードを追加する関数
Alias::AddWord() {
  local word="$1"

  # word の文字数が 0 の場合はエラーを出力する
  if [[ "${#word}" -eq 0 ]]; then
    outputErrorLog "word must be length over 1"
  fi

  # $alias_path が存在しない場合はエラーを出力する
  if [[ ! -e $alias_path ]]; then
    outputErrorLog "not found alias file:$alias_path"
  fi

  gsAddUniqueRow "$word" "$alias_path" "^" "alias add $word"
}

# alias ファイルから指定ワードを削除する関数
Alias::DeleteWord() {
  local word="$1"

  # word の文字数が 0 の場合はエラーを出力する
  if [[ "${#word}" -eq 0 ]]; then
    outputErrorLog "word must be length over 1"
  fi

  # $alias_path が存在しない場合はエラーを出力する
  if [[ ! -e $alias_path ]]; then
    outputErrorLog "not found alias file:$alias_path"
  fi

  gsDeleteLikeWord "$word" "$alias_path" "alias delete ${word//\\n/}"
}

# 別ファイルを source 行として alias ファイルに追加する関数
Alias::AddSourceFile() {
  local source_path="$1"
  local log_message="alias add ${source_path##*/}"

  # source_path が存在しない場合はエラーを出力する
  if [[ ! -e $source_path ]]; then
    outputErrorLog "not found alias source file:$source_path"
  fi

  # $alias_path が存在しない場合はエラーを出力する
  if [[ ! -e $alias_path ]]; then
    outputErrorLog "not found alias file:$alias_path"
  fi

  gsAddUniqueRow "# import ${source_path##*/}" "$alias_path" "" "$log_message"
  gsAddUniqueRow "source $source_path\n" "$alias_path" "$" "$log_message"
}

alias aliasInit='Alias::Init'
alias aliasAddWord='Alias::AddWord'
alias aliasDeleteWord='Alias::DeleteWord'
alias aliasAddSourceFile='Alias::AddSourceFile'
