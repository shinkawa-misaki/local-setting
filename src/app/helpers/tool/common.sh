namespace helpers/tool
set -e

## IMPORT ##
# ------------------------ #
import util_ext/log

## MAIN ##
# ------------------------ #
# 指定されたツールをインストールする（存在しない場合のみ）
Tool::Install() {
  local is_exist
  is_exist=$(Tool::IsExist "$1" "$2" "$4" "$5")
  # ツールが存在しない場合、インストール処理を実行
  if [[ "$is_exist" -eq 0 ]]; then
    local installCommand="$3"
    outputInfoLog "need install $2 $5"
    outputStartLog "install $2 $5"
    $installCommand
    outputResultLog $? "install $2"

    local is_exist
    is_exist=$(Tool::IsExist "$1" "$2" "$4")
    Tool::CheckInstallSuccess "$is_exist" "$installCommand"
  else
    outputInfoLog "already install $2 $5"
  fi
}

# インストール成功を確認しログに出力
Tool::CheckInstallSuccess() {
  # インストール失敗の場合はエラーログ出力
  if [[ "${1}" -eq 0 ]]; then
    outputErrorLog "${2} is Failed"
  else
    outputInfoLog "${2} is Success"
  fi
}

# 指定されたツールをアンインストールする（存在する場合のみ）
Tool::UnInstall() {
  local is_exist
  is_exist=$(Tool::IsExist "$1" "$2" "$4" "$5")
  # ツールが存在する場合、アンインストール処理を実行
  if [[ "$is_exist" -ne 0 ]]; then
    local uninstallCommand="$3"
    outputInfoLog "need uninstall $2 $5"
    outputStartLog "uninstall $2 $5"
    $uninstallCommand
    outputResultLog $? "uninstall $2"

    local is_exist
    is_exist=$(Tool::IsExist "$1" "$2" "$4" "$5")
    Tool::CheckUnInstallSuccess "$is_exist" "$uninstallCommand"
  else
    outputInfoLog "already uninstall $2 $5"
  fi
}

# アンインストール成功を確認しログに出力
Tool::CheckUnInstallSuccess() {
  # アンインストール失敗の場合はエラーログ出力
  if [[ $1 -ne 0 ]]; then
    outputErrorLog "$2 is Failed"
  else
    outputInfoLog "$2 is Success"
  fi
}

# 指定したツールが存在するか確認する
Tool::IsExist() {
 case ${1} in
  "type"    ) (type "$2" | wc -l | sed 's/ //g') 2> /dev/null || [[ $? == 1 ]];;
  "which"   ) (which "$2" | wc -l | sed 's/ //g') 2> /dev/null || [[ $? == 1 ]];;
  "app"     ) Tool::IsExistFile "/Applications/${2}.app/Contents/Info.plist";;
  "brew"    ) brew list | grep -E -c "^${2}$" 2> /dev/null || [[ $? == 1 ]];;
  "anyenv"  ) anyenv envs | grep -c "$2" 2> /dev/null || [[ $? == 1 ]];;
  "version" ) ${3} --version | grep -c "$4" 2> /dev/null || [[ $? == 1 ]];;
  "versions") ${3} versions | grep -c "$4" 2> /dev/null || [[ $? == 1 ]];;
           *) outputInfoLog "unified";;
 esac
}

# 指定されたファイルが存在するかチェックする
Tool::IsExistFile() {
  local plist_path="$1"

  if [[ -e "$plist_path" ]]; then
    echo 1
  else
    echo 0
  fi
}

# Homebrewパッケージのリンクを再作成する
Tool::ReLink() {
  local target="$1"

  brew unlink $target 2> /dev/null
  brew link --overwrite --force $target
}

# 指定された設定を削除する
Tool::DeleteSetting() {
  local target="$1"

  if [[ -e "$target" ]]; then
    local res
    res=$(sudo chmod 777 "$target" 2> /dev/null || echo 1)
    # 権限変更が成功した場合のみ削除処理を実行
    if [[ "$res" -eq 0 ]]; then
      if [[ -L "$target" ]]; then
        unlink "$target"
      elif [[ -d "$target" ]]; then
        sudo rm -rf "$target"
      else
        sudo rm "$target"
      fi
    fi
  fi
}

# PHPのバージョン環境を切り替える
Tool::PHPENV() {
  local module_domain=$1
  local target_php_version=$2

  type php >/dev/null 2>&1
  # phpが存在しない場合はツールを更新する
  if [[ $? -eq 1 ]]; then
    localSetting update "$module_domain" tool
  fi

  local current_php_version
  current_php_version="$(php --version | head -n 1 | cut -d " " -f 2)"

  local php_dir
  # PHPバージョンが異なる場合にバージョンを切り替える
  if [[ "$current_php_version" != "$target_php_version" ]]; then
    local php_dir
    php_dir="$(brew --prefix)/bin/php"

    if [[ "$(echo "$current_php_version" | cut -c 1)" == "8" && -L "$php_dir" ]]; then
      (unlink "$php_dir" && brew unlink php@${target_php_version} && brew link --overwrite php@${target_php_version}) 1> /dev/null
    else
      (brew unlink php && brew unlink php@${target_php_version} && brew link --overwrite php@${target_php_version}) 1> /dev/null
    fi
  fi
}

alias toolInstall='Tool::Install'
alias toolUnInstall='Tool::UnInstall'
alias toolIsExist='Tool::IsExist'
alias toolReLink='Tool::ReLink'
alias toolDeleteSetting='Tool::DeleteSetting'
alias toolPHPENV='Tool::PHPENV'
