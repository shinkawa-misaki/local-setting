namespace helpers
set -e

## IMPORT ##
# ------------------------ #
import util-ume/log
import util-ume/alias

## DECLARATION ##
# ------------------------ #
string -g alias_path="$HOME/.alias"

## MAIN ##
# ------------------------ #
# alias の初期設定を行う関数
AliasCommon::Setting() {
  local base_alias_path="$1"

  # $base_alias_path がファイルとして存在する場合のみコピーと追加処理を行う
  if [[ -f "$base_alias_path" ]]; then
    outputStartLog "copy ${base_alias_path##*/}"
    cp "$base_alias_path" "$HOME/${base_alias_path##*/}"
    outputResultLog $? "copy ${base_alias_path##*/}"

    aliasAddSourceFile "$HOME/${base_alias_path##*/}"
  fi
}

alias setAlias='AliasCommon::Setting'
