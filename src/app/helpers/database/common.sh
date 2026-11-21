namespace helpers/database
set -e

## IMPORT ##
# ------------------------ #
import util_ext/log
import util_ext/aws
import util_ext/date

## MAIN ##
# ------------------------ #
# データベースのクリーンアップと再ダンプを行う
Database::CleanUp() {
  local dump_path="$1"

  # ダンプファイルが存在する場合は削除
  if [[ -e "$dump_path" ]]; then
    rm $dump_path
  fi

  # 新規にダンプを取得
  Database::Dump "$dump_path"
}

# ダンプファイルが古ければクリーンアップを実施
Database::Update() {
  local dump_path="$1"

  if [[ -e "$dump_path" ]]; then
    local updated
    updated=$(dateFileUpdated "$dump_path")
    # 更新日が本日でない場合はクリーンアップ
    if [[ "$updated" != "$(dateToday)" ]]; then
      Database::CleanUp "$dump_path"
    fi
  else
    # ダンプファイルがなければクリーンアップを実施
    Database::CleanUp "$dump_path"
  fi
}

# S3からSQLダンプを取得し、必要な置換処理を行う
Database::Dump() {
  local dump_path="$1"
  local collation="$2"
  local target_dump_url="$3"
  local profile="$4"
  local log_message

  outputStartLog "dump sql..."
  local count=1
  local result=1

  # 最大10回までS3からダンプファイルを取得試行
  while [[ "$count" -lt 10 && "$result" -gt 0 ]]; do
    awsGetS3Bucket "$target_dump_url" "$dump_path.gz" "$profile"
    result=$?
    ((count++))
  done

  # ダウンロードしたファイルを展開
  gunzip "$dump_path.gz"
  outputResultLog $? "dump sql"

  # TODO dump の インポート→エクスポートエラー 一時的な処置
  log_message="${dump_path##*/} delete 50017 DEFINER"
  outputStartLog "$log_message"
  gsed -i 's/DEFINER=`[^`]+`@`[^`]+`[[:space:]]*//g' "$dump_path"
  outputResultLog $? "$log_message"

  # TODO dump のインポートエラー（文字コード） 一時的な処置
  log_message="${dump_path##*/} collation_connection set utf8mb4_0900_ai_ci to $collation"
  outputStartLog "$log_message"
  gsReplaceOFRegExp "utf8mb4_0900_ai_ci" "$collation" "$dump_path"
  outputResultLog $? "$log_message"

  # TODO dump のインポートエラー（外部キー制約） 一時的な処置
  log_message="${dump_path##*/} add top SET FOREIGN_KEY_CHECKS = 0;"
  outputStartLog "$log_message"
  gsed -i '1s/^/SET FOREIGN_KEY_CHECKS = 0;\n/' "$dump_path"
  outputResultLog $? "$log_message"

  log_message="${dump_path##*/} add last SET FOREIGN_KEY_CHECKS = 1;"
  outputStartLog "$log_message"
  gsed -i '$a\SET FOREIGN_KEY_CHECKS = 1;\n/' "$dump_path"
  outputResultLog $? "$log_message"

}

alias databaseCleanUp='Database::CleanUp'
alias databaseUpdate='Database::Update'
