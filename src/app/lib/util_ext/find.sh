namespace util_ext

## IMPORT ##
# ------------------------ #
# no dependencies
# ------------------------ #

## MAIN ##
# ------------------------ #
# 指定ディレクトリ配下のディレクトリを検索する関数
Find::OfDir() {
  local target_dir="$1"
  shift;

  # オプション引数がない場合は単純にディレクトリを検索する
  if [[ ${#@} -eq 0 ]]; then
    (find "$target_dir" -type d) || [[ $? == 1 ]]
  else
    (eval "find $target_dir -type d $@") || [[ $? == 1 ]]
  fi
}

# 指定ディレクトリ配下のファイルを検索する関数
Find::OfFile() {
  local target_dir="$1"
  shift;

  # オプション引数がない場合は単純にファイルを検索する
  if [[ ${#@} -eq 0 ]]; then
    (find "$target_dir" -type f) || [[ $? == 1 ]]
  else
    (eval "find $target_dir -type f $@") || [[ $? == 1 ]]
  fi
}

# 指定ディレクトリ配下のファイル数を数える関数
Find::OfFileCount() {
  local target_dir="$1"
  shift;

  # オプション引数がない場合は単純にファイル数をカウントする
  if [[ ${#@} -eq 0 ]]; then
    (find "$target_dir" -type f | wc -l | sed 's/ //g') || [[ $? == 1 ]]
  else
    (eval "find $target_dir -type f $@" | wc -l | sed 's/ //g') || [[ $? == 1 ]]
  fi
}

# sudo で指定ディレクトリ配下のファイルを検索する関数
Find::OfSecretFile() {
  local target_dir="$1"
  shift;

  # オプション引数がない場合は単純にファイルを検索する
  if [[ ${#@} -eq 0 ]]; then
    (sudo find "$target_dir" -type f) || [[ $? == 1 ]]
  else
    (eval "sudo find $target_dir -type f $@") || [[ $? == 1 ]]
  fi
}

# sudo で指定ディレクトリ配下のファイル数を数える関数
Find::OfSecretFileCount() {
  local target_dir="$1"
  shift;

  # オプション引数がない場合は単純にファイル数をカウントする
  if [[ ${#@} -eq 0 ]]; then
    (sudo find "$target_dir" -type f | wc -l | sed 's/ //g') || [[ $? == 1 ]]
  else
    (eval "sudo find $target_dir -type f $@" | wc -l | sed 's/ //g') || [[ $? == 1 ]]
  fi
}

# sudo で指定ディレクトリ配下の特定ファイルの数を数える関数
Find::OfSecretFileBuyNameCount() {
  local target_dir="$1"
  local target_name="$2"

  (sudo find "$target_dir" -type f -name "$target_name" | wc -l | sed 's/ //g') || [[ $? == 1 ]]
}

alias findOfDir='Find::OfDir'
alias findOfFile='Find::OfFile'
alias findOfFileCount='Find::OfFileCount'
alias findOfSecretFile='Find::OfSecretFile'
alias findOfSecretFileCount='Find::OfSecretFileCount'
alias findOfSecretFileBuyNameCount='Find::OfSecretFileBuyNameCount'
