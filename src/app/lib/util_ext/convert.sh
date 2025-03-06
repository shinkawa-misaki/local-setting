#!/usr/bin/env bash
set -e

# no dependencies
# ------------------------ #
# 重複読み込み防止用チェック
if [[ -n "${UTIL_CONVERT_LOADED}" ]]; then
    return
fi

# フラグ設定
UTIL_CONVERT_LOADED=true
# ------------------------ #
function convertCamelToPascal() {
  local word="$1"

  echo "${word}" | awk '{for(i=1; i<=NF; i++) {$i = toupper(substr($i, 1, 1)) substr($i, 2)}}1'
}

function convertPascalToCamel() {
  local word="$1"

  echo "${word}" | awk '{for(i=1; i<=NF; i++) $i = tolower(substr($i, 1, 1)) substr($i, 2)}1'
}

export -f convertCamelToPascal
export -f convertPascalToCamel
