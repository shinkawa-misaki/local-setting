namespace util-ext

## IMPORT ##
# ------------------------ #
# no dependencies
# ------------------------ #

## MAIN ##
# ------------------------ #
# 現在の日付を取得する関数
Date::Today() {
  date +"${format:-%Y%m%d}"
}

# 1 日前の日付を取得する関数
Date::Yesterday() {
  date +"${format:-%Y%m%d}" --date '1 day ago' 2> /dev/null || date -v-1d +"${format:-%Y%m%d}"
}

# ========================================================================
# date +"${format:-%Y%m%d}" --date "${year}${month}${day}" 2> /dev/null || date -jf "%Y%m%d" "${year}${month}${day}" "+${format}"
# ========================================================================
# date --date "${year}${month}${day}" +"${format:-%Y%m%d}" 2> /dev/null \
#    || date -jf "%Y%m%d" "${year}${month}${day}" "+${format:-%Y%m%d}" \
#    || date -jf "%Y%m%d" "${year}${month}${day}" +"${format:-%Y%m%d}"
# 三段構えフォールバック提案
#========================================================================

# 指定した日付を整形して取得する関数
Date::TargetDay() {
  local target_day="${1:-$(Date::Yesterday)}"
  local year
  local month
  local day
  year=$(echo "$target_day" | gsed -r 's/^([0-9]{4}).*([0-9]{2}).*([0-9]{2})$/\1/')
  month=$(echo "$target_day" | gsed -r 's/^([0-9]{4}).*([0-9]{2}).*([0-9]{2})$/\2/')
  day=$(echo "$target_day" | gsed -r 's/^([0-9]{4}).*([0-9]{2}).?([0-9]{2})$/\3/')

  date +"${format:-%Y%m%d}" --date "${year}${month}${day}" 2> /dev/null || date -jf "%Y%m%d" "${year}${month}${day}" "+${format}"
}

# 指定した日数前の日付を取得する関数
Date::TargetAgoDay() {
  local target_days="${1:-1}"

  date +"${format:-%Y%m%d}" --date "${target_days} day ago" 2> /dev/null || eval "date -v-${target_days}d +${format:-%Y%m%d}"
}

# ファイルの更新日を取得し、存在しない場合は現在の日付を返す関数
Date::FileUpdated() {
  local target_file="$1"
  local format="$2"

  # $target_file が存在する場合のみファイル更新日を取得する
  if [[ -e "$target_file" ]]; then
    date -r "$target_file" +"${format:-%Y%m%d}"
  else
    Date::Today
  fi
}

alias dateToday='Date::Today'
alias dateYesterday='Date::Yesterday'
alias dateTargetDay='Date::TargetDay'
alias dateTargetAgoDay='Date::TargetAgoDay'
alias dateFileUpdated='Date::FileUpdated'
