namespace helpers
set -e

## IMPORT ##
# ------------------------ #
import util-ume/awk

## MAIN ##
# ------------------------ #
# 2つのファイルを比較し、差分があれば上書きするための関数 (Patch 的処理)
Patch::Execute() {
  local default_path="$1"
  local back_up_path="$2"
  local target_dir="$3"
  local result=0

  # default_path が存在しない場合はエラーを出力する
  if [[ ! -f "$default_path" ]]; then
    outputErrorLog "not found target_file:$default_path"
    result=1
  fi

  # back_up_path が存在しない場合はエラーを出力する
  if [[ ! -f "$back_up_path" ]]; then
    outputErrorLog "not found target_file:$back_up_path"
    result=1
  fi

  # ここまででエラーがなければパッチ処理を実行
  if [[ "$result" -ne 1 ]]; then
    # default_path と back_up_path ともに空でない場合のみ処理
    if [[ -s "$default_path" && -s "$back_up_path" ]]; then
      local log_message="execute patch"
      outputStartLog "$log_message of grep ${default_path##*/} to ${back_up_path##*/}"

      # target_dir 内のファイルとバックアップファイルの共通行を一時ファイルとして取得
      local tmp_exclude
      tmp_exclude=$(mktemp)

      # target_dir がディレクトリの場合で空でない場合のみ、共通行を抽出
      if [[ -d "$target_dir" && -n "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
        outputStartLog "$log_message create temp file  of dir is not empty"
        awk 'NR==FNR{lines[$0];next} $0 in lines' "$back_up_path" "$target_dir"/* > "$tmp_exclude"
        outputResultLog "$?" "$log_message create temp file  of dir is not empty"
      else
        outputStartLog "$log_message create empty temp file"
        : > "$tmp_exclude"
        outputResultLog "$?" "$log_message create empty temp file"
      fi

      local cleaned_file="${default_path}_cleaned"
      : > "$cleaned_file"

      # バックアップファイルを順番通りに読み込み、既存の行や共通行などを除いたうえで cleaned_file の末尾に追記
      outputStartLog "$log_message create cleaned temp file"
      if [[ -s $tmp_exclude ]]; then
        awkGetUniqRows "$tmp_exclude" "$back_up_path" > "${cleaned_file}.tmp"
        outputResultLog "$?" "$log_message create cleaned temp file"
      else
        cat "$default_path" > "$cleaned_file"
        awkGetUniqRows "$default_path" "$back_up_path" > "${cleaned_file}.tmp"
        outputResultLog "$?" "$log_message create cleaned temp file"
      fi

      # 無駄な空行を削除してから、cleaned_file の末尾に追記
      outputStartLog "$log_message create cleaned file"
      awkDeleteEmptyRows "${cleaned_file}.tmp" >> "$cleaned_file" && rm "${cleaned_file}.tmp"
      outputResultLog "$?" "$log_message create cleaned file"

      # 差分がある場合のみ上書きする
      if ! diff -q "$default_path" "$cleaned_file" >/dev/null; then
        mv "$cleaned_file"  "$default_path"
        chmod 600 "$default_path"
        result=$?
        outputResultLog "$result" "$log_message of grep ${default_path##*/} to ${back_up_path##*/}"
      else
        rm "$cleaned_file"
        outputResultLog 0 "No differences found. Skipping update."
      fi

      rm -f "$tmp_exclude"
    fi
  fi
}

alias patchExecute='Patch::Execute'
