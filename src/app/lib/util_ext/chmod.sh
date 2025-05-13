namespace util_ext/chmod

## IMPORT ##
# ------------------------ #
import util_ext/find
import util_ext/log

## MAIN ##
# ------------------------ #
# 秘密ディレクトリを作成する関数
Chmod::CreateSecretDir() {
  local secret_dir="$1"
  local target_dir="$2"

  # $target_dir が存在しない場合のみ作成する
  if [[ ! -d "$target_dir" ]]; then
    Chmod::PublicDirALL "$secret_dir"
    outputStartLog "create secret dir to $target_dir"
    mkdir -p "$target_dir"
    Chmod::SecretDirAll "$secret_dir"
    outputResultLog $? "create secret dir to $target_dir"
  fi
}

# 秘密ファイルを作成する関数
Chmod::CreateSecretFile() {
  local secret_dir="$1"
  local target_path="$2"

  # $target_path が存在しない場合のみ作成する
  if [[ ! -f "$target_path" ]]; then
    Chmod::PublicDirALL "$secret_dir"
    outputStartLog "create secret file to $target_dir"
    touch "$target_path"
    Chmod::SecretFile "$target_path"
    Chmod::SecretDirAll "$secret_dir"
    outputResultLog $? "create secret file to $target_dir"
  fi
}

# 秘密ディレクトリ配下にさらに秘密ディレクトリを作成する関数
Chmod::CreateSecretDirOfSecretDir() {
  local secret_dir="$1"
  local target_dir="$2"

  # $target_dir が存在しない場合のみ作成する
  if [[ ! -d "$target_dir" ]]; then
    outputStartLog "create secret dir to $target_dir"
    Chmod::PublicDirALL "$secret_dir"
    mkdir -p "$target_dir"
    Chmod::SecretDirAll "$secret_dir"
    outputResultLog $? "create secret dir to $target_dir"
  fi
}

# 秘密ディレクトリ配下にさらに秘密ファイルを作成する関数
Chmod::CreateSecretFileOfSecretDir() {
  local secret_dir="$1"
  local target_path="$2"

  # $target_path が存在しない場合のみ作成する
  if [[ ! -f "$target_path" ]]; then
    outputStartLog "create secret file to $target_dir"
    Chmod::PublicDirALL "$secret_dir"
    touch "$target_path"
    Chmod::SecretDirAll "$secret_dir"
    outputResultLog $? "create secret file to $target_dir"
  fi
}

# 秘密ディレクトリをコピーする関数
Chmod::CopyOfSecretDir() {
  local main_dir="$1"
  local target_dir="$2"
  local tmp_dir="${target_dir//$HOME\//@}"
  local secret_dir
  secret_dir="$(echo ${tmp_dir%%/*} | sed 's/@/$HOME/')"

  Chmod::CreateSecretDir "$secret_dir" "$target_dir"

  outputStartLog "copy secret dir $main_dir to $target_dir"
  cp -rf "$main_dir" "$target_dir"
  outputResultLog $? "copy secret dir $main_dir to $target_dir"
}

# 秘密ファイルをコピーする関数
Chmod::CopyOfSecretFile() {
  local main_file="$1"
  local target_dir="$2"

  outputStartLog "copy secret file $main_file to $target_dir"
  cp -af "$main_file" "$target_dir"
  outputResultLog $? "copy secret file $main_file to $target_dir"
}

# 指定ディレクトリ配下のディレクトリとファイルを秘密権限に変更する関数
Chmod::SecretDirAll() {
  local target_dir="$1"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    Chmod::SecretDir "$target_dir" && Chmod::SecretFile "$target_dir"
  fi
}

# 指定ディレクトリ配下のディレクトリを秘密権限(700)にする関数
Chmod::SecretDir() {
  local target_dir="$1"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    find "$target_dir" -type d -print0 | xargs -0 chmod 700
  fi
}

# 指定ディレクトリ配下のファイルを秘密権限(600)にする関数
Chmod::SecretFile() {
  local target_dir="$1"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    find "$target_dir" -type f -print0 | xargs -0 chmod 600
  fi
}

# 指定ディレクトリ配下の特定ファイルを秘密権限(600)にする関数
Chmod::SecretFileOfName() {
  local target_dir="$1"
  local target_name="$2"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    find "$target_dir" -type f -name "$target_name" -print0 | xargs -0 chmod 600
  fi
}

# 指定ディレクトリ配下のディレクトリとファイルを公開権限に変更する関数
Chmod::PublicDirALL() {
  local target_dir="$1"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    Chmod::PublicDir "$target_dir" && Chmod::PublicFiles "$target_dir"
  fi
}

# 指定ディレクトリ配下のディレクトリを公開権限(744)にする関数
Chmod::PublicDir() {
  local target_dir="$1"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    find "$target_dir" -type d -print0 | xargs -0 chmod 744
  fi
}

# 指定ディレクトリ配下のファイルを公開権限(644)にする関数
Chmod::PublicFiles() {
  local target_dir="$1"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    find "$target_dir" -type f -print0 | xargs -0 chmod 644
  fi
}

# 指定ディレクトリ配下の特定ファイルを公開権限(644)にする関数
Chmod::PublicFilesOfName() {
  local target_dir="$1"
  local target_name="$2"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    find "$target_dir" -type f -name "$target_name" -print0 | xargs -0 chmod 644
  fi
}

# 指定ディレクトリ配下のファイルの所有者をユーザー自身に変更する関数
Chmod::FilesOwnerOfUser() {
  local target_dir="$1"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    find "$target_dir" -type f -print0 | xargs -0 chown "$USER" || [[ $? == 1 ]]
    # 上記が失敗した場合は sudo 実行、それでも失敗する場合は警告
    if [[ $? == 1 ]]; then
      find "$target_dir" -type f -print0 | xargs -0 sudo chown "$USER" || [[ $? == 1 ]]
      if [[ $? == 1 ]]; then
        outputWarnLog "chmod: changing permissions of '$target_dir' Operation not permitted!"
        outputWarnLog "ヘルプデスクにPCを持っていき、root権限が使えるように申請してください。"
      fi
    fi
  fi
}

# 指定ディレクトリ配下全体(ディレクトリ・ファイル)の所有者をユーザー自身に変更する関数
Chmod::DirAllOwnerOfUser() {
  local target_dir="$1"

  # $target_dir がディレクトリの場合のみ処理を行う
  if [[ -d "$target_dir" ]]; then
    find "$target_dir" -print0 | xargs -0 chown "$USER"  || [[ $? == 1 ]]
    # 上記が失敗した場合は sudo 実行、それでも失敗する場合は警告
    if [[ $? == 1 ]]; then
      find "$target_dir" -print0 | xargs -0 sudo chown "$USER"  || [[ $? == 1 ]]
      if [[ $? == 1 ]]; then
       outputWarnLog "chmod: changing permissions of '$target_dir' Operation not permitted!"
       outputWarnLog "ヘルプデスクにPCを持っていき、root権限が使えるように申請してください。"
      fi
    fi
  fi
}

alias createSecretDir='Chmod::CreateSecretDir'
alias createSecretFile='Chmod::CreateSecretFile'
alias createSecretDirOfSecretDir='Chmod::CreateSecretDirOfSecretDir'
alias createSecretFileOfSecretDir='Chmod::CreateSecretFileOfSecretDir'
alias copyOfSecretDir='Chmod::CopyOfSecretDir'
alias copyOfSecretFile='Chmod::CopyOfSecretFile'
alias secretDirALL='Chmod::SecretDirAll'
alias secretDir='Chmod::SecretDir'
alias secretFiles='Chmod::SecretFile'
alias secretFilesOfName='Chmod::SecretFileOfName'
alias publicDirALL='Chmod::PublicDirALL'
alias publicDir='Chmod::PublicDir'
alias publicFiles='Chmod::PublicFiles'
alias publicFilesOfName='Chmod::PublicFilesOfName'
alias filesOwnerOfUser='Chmod::FilesOwnerOfUser'
alias dirAllOwnerOfUser='Chmod::DirAllOwnerOfUser'
