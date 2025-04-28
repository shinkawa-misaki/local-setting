namespace util-ext

## IMPORT ##
# ------------------------ #
import util-ext/log
import util-ext/grep
import util-ext/gsed

## MAIN ##
# ------------------------ #
# zshrc ファイルの初期設定を行う関数
Zshrc::Init() {
  # zshrc_path が存在しない場合にファイルを作成する
  if [[ ! -f $zshrc_path ]]; then
    outputInfoLog "touch $zshrc_path"
    touch "$zshrc_path"
  fi
}

# zshrc ファイルにワードを追加する関数
Zshrc::AddWord() {
  local word="$1"

  # word の文字数が 0 の場合はエラーを出力する
  if [[ "${#word}" -eq 0 ]]; then
    outputErrorLog "word must be length over 1"
  fi

  # zshrc_path が存在しない場合はエラーを出力する
  if [[ ! -f $zshrc_path ]]; then
    outputErrorLog "not found zshrc file:$zshrc_path"
  fi

  gsAddUniqueRow "$word" "$zshrc_path" "^" "zshrc add $word"
}

# zshrc ファイルからワードを削除する関数
Zshrc::DeleteWord() {
  local word="$1"

  # word の文字数が 0 の場合はエラーを出力する
  if [[ "${#word}" -eq 0 ]]; then
    outputErrorLog "word must be length over 1"
  fi

  # zshrc_path が存在しない場合はエラーを出力する
  if [[ ! -f $zshrc_path ]]; then
    outputErrorLog "not found zshrc file:$zshrc_path"
  fi

  outputStartLog "zshrc delete ${word//\\n/}"
  gsDeleteLikeWord "$word" "$zshrc_path"
  outputResultLog $? "zshrc delete ${word//\\n/}"
}

# 別ファイルを source 行として zshrc ファイルに追加する関数
Zshrc::AddSourceFile() {
  local source_path="$1"
  local log_message="zshrc add ${source_path##*/}"

  # source_path が存在しない場合はエラーを出力する
  if [[ ! -f "$source_path" ]]; then
    outputErrorLog "not found zshrc source file:$source_path"
  fi

  # zshrc_path が存在しない場合はエラーを出力する
  if [[ ! -f $zshrc_path ]]; then
    outputErrorLog "not found zshrc file:$zshrc_path"
  fi

  gsAddUniqueRow "# import ${source_path##*/}" "$zshrc_path" "" "$log_message"
  gsAddUniqueRow "source $source_path\n" "$zshrc_path" "" "$log_message"
}

# zshrc_original ファイルの初期設定を行う関数
ZshrcOriginal::Init() {
  # zshrc_original_path が存在しない場合にファイルを作成し、zshrc で読み込む
  if [[ ! -f "$zshrc_original_path" ]]; then
    outputInfoLog "touch $zshrc_original_path"
    touch "$zshrc_original_path"
  fi

  Zshrc::AddSourceFile "$zshrc_original_path"
}

# zshrc_original ファイル内の文字列を置き換える関数
ZshrcOriginal::ReplaceWord() {
  local word="$1"
  local replace_word="$2"

  # word, replace_word が空の場合はエラーを出力する
  if [[ "${#word}" -eq 0 ]] || [[ "${#replace_word}" -eq 0 ]]; then
    outputErrorLog "word or replace_word must be length over 1"
  fi

  # zshrc_original_path が存在しない場合はエラーを出力する
  if [[ ! -f $zshrc_original_path ]]; then
    outputErrorLog "not found zshrc_original file:$zshrc_original_path"
  fi

  outputStartLog "zshrc_original_path replace $word"
  gsReplace "$word" "$replace_word" "$zshrc_original_path"
  outputResultLog $? "zshrc_original_path replace $word"
}

# zshrc_original ファイル内の文字列を正規表現で置き換える関数
ZshrcOriginal::ReplaceWordOfRegExp() {
  local word="$1"
  local replace_word="$2"

  # word, replace_word が空の場合はエラーを出力する
  if [[ "${#word}" -eq 0 ]] || [[ "${#replace_word}" -eq 0 ]]; then
    outputErrorLog "word or replace_word must be length over 1"
  fi

  # zshrc_original_path が存在しない場合はエラーを出力する
  if [[ ! -f $zshrc_original_path ]]; then
    outputErrorLog "not found zshrc_original file:$zshrc_original_path"
  fi

  outputStartLog "zshrc_original_path replace $word of RegExp"
  gsReplaceOFRegExpFirst "$word" "$replace_word" "$zshrc_original_path"
  outputResultLog $? "zshrc_original_path replace $word of RegExp"
}

# zshrc_original ファイルにワードを追加する関数
ZshrcOriginal::AddWord() {
  local word="$1"
  local log_message="zshrcOriginal add $word"

  # word の文字数が 0 の場合はエラーを出力する
  if [[ "${#word}" -eq 0 ]]; then
    outputErrorLog "word must be length over 1"
  fi

  # zshrc_original_path が存在しない場合はエラーを出力する
  if [[ ! -f $zshrc_original_path ]]; then
    outputErrorLog "not found zshrc_original file:$zshrc_original_path"
  fi

  gsAddUniqueRow "$word" "$zshrc_original_path" "^" "$log_message"
}

# zshrc_original ファイルからワードを削除する関数
ZshrcOriginal::DeleteWord() {
  local word="$1"

  # word の文字数が 0 の場合はエラーを出力する
  if [[ "${#word}" -eq 0 ]]; then
    outputErrorLog "word must be length over 1"
  fi

  # zshrc_original_path が存在しない場合はエラーを出力する
  if [[ ! -f $zshrc_original_path ]]; then
    outputErrorLog "not found zshrc_original file:$zshrc_original_path"
  fi

  outputStartLog "zshrcOriginal delete ${word//\\n/}"
  gsDeleteLikeWord "$word" "$zshrc_original_path"
  outputResultLog $? "zshrcOriginal delete ${word//\\n/}"
}

# 別ファイルを source 行として zshrc_original ファイルに追加する関数
ZshrcOriginal::AddSourceFile() {
  local source_path="$1"
  local log_message="zshrcOriginal add ${source_path##*/}"

  # source_path が存在しない場合はエラーを出力する
  if [[ ! -f "$source_path" ]]; then
    outputErrorLog "not found zshrc_original source file:$source_path"
  fi

  # zshrc_original_path が存在しない場合はエラーを出力する
  if [[ ! -f "$zshrc_original_path" ]]; then
    outputErrorLog "not found zshrc_original file:$zshrc_original_path"
  fi

  gsAddUniqueRow "# import ${source_path##*/}" "$zshrc_original_path" "" "$log_message"
  gsAddUniqueRow "source $source_path\n" "$zshrc_original_path" "" "$log_message"
}

alias zshrcInit='Zshrc::Init'
alias zshrcAddWord='Zshrc::AddWord'
alias zshrcDeleteWord='Zshrc::DeleteWord'
alias zshrcAddSourceFile='Zshrc::AddSourceFile'
alias zshrcOriginalInit='ZshrcOriginal::Init'
alias zshrcOriginalReplaceWord='ZshrcOriginal::ReplaceWord'
alias zshrcOriginalReplaceWordOfRegExp='ZshrcOriginal::ReplaceWordOfRegExp'
alias zshrcOriginalAddWord='ZshrcOriginal::AddWord'
alias zshrcOriginalDeleteWord='ZshrcOriginal::DeleteWord'
alias zshrcOriginalAddSourceFile='ZshrcOriginal::AddSourceFile'
