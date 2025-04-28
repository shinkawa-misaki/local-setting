namespace util-ext/awk

## IMPORT ##
# ------------------------ #
# no dependencies
# ------------------------ #

## MAIN ##
# ------------------------ #

# 指定ファイルから除外対象を除外し、空行の重複を排除して出力する
Awk::GetUniqRows() {
  local target_file="$1"
  local exclude="$2"

  awk '
    NR==FNR { exclude[$0]; next }                      # 最初のファイルの行をexclude配列に登録
    /^[[:space:]]*$/ { if (blank++ == 0) print; next } # 空行の重複を排除し、最初の空行のみ出力
    {
      blank = 0
      if (!($0 in exclude)) print                       # exclude配列に存在する行を出力
    }
  ' "$target_file" "$exclude"
}

# 指定ファイルから空行の重複を排除し、最初の空行のみ出力する
Awk::DeleteEmptyRows() {
  local target_file="$1"

  awk '
    /^[[:space:]]*$/ {
      if (++blank <= 1) print # 空行の重複を排除し、最初の空行のみ出力
      next
    }
    { blank = 0; print }      # 空行でない行をそのまま出力
  ' "$target_file"
}

alias awkGetUniqRows='Awk::GetUniqRows'
alias awkDeleteEmptyRows='Awk::DeleteEmptyRows'
