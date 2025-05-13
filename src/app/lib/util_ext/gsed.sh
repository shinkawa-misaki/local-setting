namespace util_ext

## IMPORT ##
# ------------------------ #
import util_ext/log
import util_ext/grep

## MAIN ##
# ------------------------ #
# 文字列を置換する関数 (gsed を使用)
GSed::Replace() {
  local target_word="$1"
  local replace_word

  # 特殊文字をエスケープ
  replace_word=$(GSed::EscapeRegex "${2//\|/\\\|}")
  local target_file="$3"

  gsed -i -e 's|'$target_word'|'$replace_word'|g' $target_file
}

# 文字列を置換する関数 (sudo + gsed を使用)
GSed::ReplaceSudo() {
  local target_word="$1"
  local replace_word

  # 特殊文字をエスケープ
  replace_word=$(GSed::EscapeRegex "${2//\|/\\\|}")
  local target_file="$3"

  sudo gsed -i -e 's|'"$target_word"'|'"$replace_word"'|g' "$target_file"
}

# 正規表現を用いて文字列を置換する関数 (gsed を使用)
GSed::ReplaceOFRegExp() {
  local target_word="$1"
  local replace_word="$2"
  local target_file="$3"

  gsed -i -re 's|'$target_word'|'$replace_word'|g' "$target_file"
}

# 正規表現の先頭行だけを置換する関数
GSed::ReplaceOFRegExpFirst() {
  local target_word="$1"
  local replace_word="$2"
  local target_file="$3"

  gsed -i -re 's|'$target_word'|'$replace_word'|' "$target_file"
}

# 文字列をキャメルケースに変換する関数
GSed::ReplaceCamelCase() {
  local target_word="$1"

  echo "$target_word" | gsed -re 's/.*/\L\0/g; s/(^|-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;'
}

# 指定ファイルに行を追加する関数
GSed::Add() {
  local target_file="$1"
  local target_word="$2"
  local search_word="$3"
  local search_option=${4:-after}

  local search_word_is_exist=0
  # search_word が空でない場合のみ検索を実行
  if [[ ${#search_word} -ne 0 ]]; then
    search_word_is_exist=$(grepOfFile "$search_word" "$target_file")
  fi

  # ファイルが空 (または存在しない) 場合は先頭に行を追加
  if [[ ! -s "$target_file" ]]; then
    echo -e "\n" > "$target_file"
    gsed -i -e "1i $target_word" "$target_file"
  # 検索ワードが見つかった場合は前後に挿入
  elif [[ $search_word_is_exist -ne 0 ]]; then
    if [[ $search_option == "after" ]]; then
      gsed -i -e "/$search_word/N; s/\n/\n$target_word\n/;" "$target_file"
    else
      gsed -i -e "/$search_word/{x; s/^/$target_word\n/; x;}" "$target_file"
    fi
  # 見つからなければファイル末尾に追記
  else
    gsed -i -re "\$a $target_word" "$target_file"
  fi
}

# sudo 権限で指定ファイルに行を追加する関数
GSed::AddSudo() {
  local target_file="$1"
  local target_word="$2"
  local search_word="$3"
  local search_option=${4:-after}

  local search_word_is_exist=0
  # search_word が空でない場合のみ検索を実行
  if [[ ${#search_word} -ne 0 ]]; then
    search_word_is_exist=$(grepOfFile "$search_word" "$target_file")
  fi

  # ファイルが存在しない場合は先頭に行を追加
  if [[ ! -f "$target_file" ]]; then
    echo -e "\n" > "$target_file"
    sudo gsed -i -e "1i $target_word" "$target_file"
  # 検索ワードが見つかった場合は前後に挿入
  elif [[ $search_word_is_exist -ne 0 ]]; then
    if [[ $search_option == "after" ]]; then
      sudo gsed -i -e "/$search_word/N; s/\n/\n$target_word\n/;" "$target_file"
    else
      sudo gsed -i -e "/$search_word/{x; s/^/$target_word\n/; x;}" "$target_file"
    fi
  # 見つからなければファイル末尾に追記
  else
    sudo gsed -i -re "\$a $target_word" "$target_file"
  fi
}

# 指定行番号にワードを挿入する関数
GSed::AddTargetRowNo() {
  local target_row_no="$1"
  local target_word="$2"
  local target_file="$3"
  local end_row
  end_row="$(less "$target_file" | wc -l)"

  local search_word_is_exist
  # search_word が空文字でない場合のみ grep でファイルを検索し、結果を search_word_is_exist に代入する
  if [[ ${#search_word} -ne 0 ]]; then
    search_word_is_exist=$(grepOfFile "$search_word" "$target_file")
  fi

  # 対象ファイルが存在しない場合は新規作成し、先頭に追記する
  if [[ ! -f "$target_file" ]]; then
    sudo echo -e "\n" > "$target_file"
    sudo gsed -i -e "1i $target_word" "$target_file"
  # search_word_is_exist が 0 でない(= 検索ワードが既に存在する)場合は検索ワードの前後に挿入する
  elif [[ $search_word_is_exist -ne 0 ]]; then
    # search_option が "after" の場合のみ検索ワードの直後に追記する
    if [[ $search_option == "after" ]]; then
      sudo gsed -i -e "/$search_word/N; s/\n/\n$target_word\n/;" "$target_file"
    else
      sudo gsed -i -e "/$search_word/{x; s/^/$target_word\n/; x;}" "$target_file"
    fi
  # それ以外はファイルの末尾に追記する
  else
    sudo gsed -i -re "\$a $target_word" "$target_file"
  fi

}

# 既存の search_word を探してそこに行を追加する関数
GSed::AddTargetWord() {
  local search_word="$1"
  local target_word="$2"
  local target_file="$3"

  GSed::Add "$target_file" "$target_word" "$search_word"
}

# 指定した行が存在しない場合のみ追記する関数
GSed::AddUniqueRow() {
  local target_word="$1"
  local target_file="$2"
  local grep_option="$3"
  local log_message="$4"

  local is_exist
  is_exist=$(grepOfFile "$target_word" "$target_file" "$grep_option")
  # 行が存在せず、かつ target_word が空文字でない場合のみ追加
  if [[ "$is_exist" -eq 0 ]] && [[ ${#target_word} -ne 0 ]]; then
    if [[ ${#log_message} -eq 0 ]]; then
      log_message="${target_file##*/} add $target_word"
    fi

    outputStartLog "$log_message"
    GSed::Add "$target_file" "$target_word"
    outputResultLog $? "$log_message"
  fi
}

# sudo 権限で、指定した行が存在しない場合のみ追記する関数
GSed::AddUniqueRowSudo() {
  local target_word="$1"
  local target_file="$2"
  local grep_option="$3"
  local log_message="$4"

  local is_exist
  is_exist=$(grepOfFile "$target_word" "$target_file" "$grep_option")

  # 行が存在せず、かつ target_word が空文字でない場合のみ追加
  if [[ "$is_exist" -eq 0 ]] && [[ ${#target_word} -ne 0 ]]; then
    if [[ ${#log_message} -eq 0 ]]; then
      log_message="${target_file##*/} add $target_word"
    fi

    outputStartLog "$log_message"
    GSed::AddSudo "$target_file" "$target_word"
    outputResultLog $? "$log_message"
  fi
}

# 検索ワードが存在しなければ追加する関数 (search_option 指定も可能)
GSed::AddUniqueRowWithTargetWord() {
  local search_word="$1"
  local target_word="$2"
  local target_file="$3"
  local search_option="$4"
  local grep_option="$5"
  local log_message="$6"

  local is_exist
  is_exist=$(grepOfFile "$target_word" "$target_file" "$grep_option")

  # 行が存在せず、かつ target_word が空文字でない場合のみ追加
  if [[ "$is_exist" -eq 0 ]] && [[ ${#target_word} -ne 0 ]]; then
    if [[ ${#log_message} -eq 0 ]]; then
      log_message="${target_file##*/} add $target_word"
    fi

    outputStartLog "$log_message"
    GSed::Add "$target_file" "$target_word" "$search_word" "$search_option"
    outputResultLog $? "$log_message"
  fi
}

# 指定行番号を元にターゲットファイルへ行を挿入する関数
GSed::AddTargetRowNo() {
  local target_row_no="$1"
  local target_word="$2"
  local target_file="$3"
  local end_row
  end_row="$(less "$target_file" | wc -l)"

  # 行番号が 0 かつファイルが存在しない場合は新規作成＋先頭に追記
  if [[ "$target_row_no" -eq 0 && ! -f "$target_file" ]]; then
    echo -e "\n" > "$target_file"
    gsed -i -e "1i $target_word" "$target_file"
  elif [[ "$target_row_no" -lt "$end_row" ]]; then
    gsed -i -e "${target_row_no}i $target_word" "$target_file"
  else
    gsed -i -re "\$a $target_word" "$target_file"
  fi
}

# 特定の文字列が何行目かを取得する関数
Gsed::GetTargetRowNo() {
  local target_word="$1"
  local target_file="$2"

  (gsed -n "/$word/=" "$target_file" 2>/dev/null) || [[ $? == 1 ]]
}

# 指定区間の行を取得する関数
GSed::GetTargetRows() {
  local start_point="$1"
  local end_point="$2"
  local target_file="$3"

  (gsed -n "$start_point,$end_point" "$target_file")
}

# 指定文字列にマッチする行を削除する関数
GSed::DeleteLikeWord() {
  local target_word="$1"
  local target_file="$2"
  local log_message="$3"

  if [[ ${#log_message} -eq 0 ]]; then
    log_message="${target_file##*/} delete $target_word"
  fi

  outputStartLog "$log_message"
  gsed -i -e "/$target_word/d" $target_file
  outputResultLog $? "$log_message"
}

# 指定区間の行を削除する関数
GSed::DeleteTargetRows() {
  local start_point="$1"
  local end_point="$2"
  local target_file="$3"

  gsed -i "${start_point},${end_point}d" "$target_file"
}

# 特殊文字をエスケープする関数
GSed::EscapeRegex() {
  local target_word="$1"

  echo "$target_word" | gsed "s/'[][|.*+?{}()^#$\/]/\\&/g"
}

# 文字を毛パブケースに起きえる
GSed::EscapeKebabCase() {
  local target_word="$1"

  echo "$target_word" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;'
}

# AWSのシークレットマネージャーから取得した.envのJSON用に文字列をエスケープする関数
GSed::EscapeJson() {
  local target_file="$1"

  # ファイルが存在しない場合はエラーを出力する
  if [[ ! -f $target_file ]]; then
    outputErrorLog "not found target_file:$target_file"
  fi

  cat "$target_file" | \
  gsed -re "/(^#|^$|APP_|^[A-Z_]*=$)/d; s/(export |\')//g;  s/^/\"/g; s/$/\"/g; s/=/\":\"/g; s/\#/\\&/g" | \
  gsed -e ':loop' -e 'N; $!b loop' -e 's/\n/,/g' -e 's/^/\{ /g; s/$/ \}/g'
}

alias gsReplace='GSed::Replace'
alias gsReplaceSudo='GSed::ReplaceSudo'
alias gsReplaceOFRegExp='GSed::ReplaceOFRegExp'
alias gsReplaceOFRegExpFirst='GSed::ReplaceOFRegExpFirst'
alias gsReplaceCamelCase='GSed::ReplaceCamelCase'
alias gsAddTargetWord='GSed::AddTargetWord'
alias gsAddTargetRowNo='GSed::AddTargetRowNo'
alias gsAddUniqueRow='GSed::AddUniqueRow'
alias gsAddUniqueRowSudo='GSed::AddUniqueRowSudo'
alias gsAddUniqueRowWithTargetWord='GSed::AddUniqueRowWithTargetWord'
alias gsGetTargetRowNo='Gsed::GetTargetRowNo'
alias gsDeleteLikeWord='GSed::DeleteLikeWord'
alias gsDeleteTargetRows='GSed::DeleteTargetRows'
alias gsEscapeRegex='GSed::EscapeRegex'
alias gsEscapeKebab='GSed::EscapeKebabCase'
alias gsEscapeJson='GSed::EscapeJson'
