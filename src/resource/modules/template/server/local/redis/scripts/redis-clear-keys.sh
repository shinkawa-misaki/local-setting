#!/bin/ash

execute="$1"
pattern="$2"
redis_no="${3:-1}"
ttl="$4"
bk_suffix="${5:-$(date +${format:-'%Y%m%d'})_bk}"
IFS=' ' read -r -a patterns < <(echo "$pattern")

if [ -z "$pattern" ] && [ "$execute" != "go" ] && [ "$execute" != "login" ]; then
  echo "usage: ${0} pattern"
  exit 1
fi

executeCommand() {
  local command="$1"
  local execute="$2"

  showList "$execute" | sed -e 's/\\/\\\\/g' | xargs -r -I {} redis-cli --raw -n "$redis_no" "$command"
}

showList() {
  local execute="$1"
  local cursor=0

  if [ -n "$execute" ]; then
    if [ "$execute" = "bk" ] || [ "$execute" = "rb" ]; then
      patterns=(
        $(echo "${patterns[*]}" | \
          tr ' ' '\n' | \
          sed "s/$/_${bk_suffix}/g" \
        )
      )
    fi
  fi

  while :; do
    local output
    local keys=()

    # SCAN 実行（カーソルを更新しながら全件取得）
    if [ ${#patterns[*]} -eq 1 ]; then
      output="$(getKeysOfPattern "$cursor" "${patterns[0]}")"
    else
      output="$(getKeysOfPatterns "$cursor")"
    fi

    # 取得した内容を内容がから（emptyを含む）重複を削除した値を抽出して配列に格納
    keys=$(echo "$output" | grep -vE '^(empty|$)' | awk '!seen[$0]++')

    # カーソルを取得
    cursor=$(echo "$keys" | head -n 1)

    if [ $(echo "$keys" | wc -l) -gt 1 ]; then
      # キーを取得し、取得したキーを表示
      echo "$keys" | tail -n +2 | tr ' ' '\n'
    fi

    # カーソルが "0" になったら終了
    if [ "$cursor" -eq 0 ]; then
      break
    fi
  done
}

getKeysOfPattern() {
  local cursor="$1"
  local pattern="$2"

  redis-cli -n "$redis_no" SCAN "$cursor" MATCH "$pattern" COUNT 2500
}

getKeysOfPatterns() {
  local cursor="$1"

  echo "${patterns[*]}" | \
    tr ' ' '\n' | \
    sed "s/^/SCAN $cursor MATCH \"/g; s/$/\" COUNT 2500/g" | \
    redis-cli -n "$redis_no"
}

login() {
  redis-cli
}

if [ "$execute" = "go" ]; then
  executeCommand "DEL \"{}\" | grep -v 1"
elif [ "$execute" = "ex" ]; then
  executeCommand "EXPIRE \"{}\" $ttl | grep -v 'OK'"
elif [ "$execute" = "bk" ]; then
  executeCommand "RENAME \"{}\" \"{}_${bk_suffix}\" | grep -v 'OK'"
  showList "$execute"
elif [ "$execute" = "rb" ]; then
  executeCommand "RENAME \"{}\" \"\$(echo {} | sed s/_${bk_suffix}$//g)\" | grep -v 'OK'" "$execute"
  showList
elif [ "$execute" = "keys" ]; then
  showList
else
  login
fi
