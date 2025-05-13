#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace commands

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util_ext/log
import helpers/config
import util_ext/docker
import util_ext/providers
import helpers/database/common

## MAIN ##
# ------------------------ #
# 引数に「clean」が指定された場合、全Docker環境を削除
if [[ "${1}" == "clean" ]]; then
  dockerALLDestroy
fi

# 引数が「clean」でない場合、Docker設定を初期化
if [[ "${1}" != "clean" ]]; then
  string module="$(echo "${1}" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  string module_shell_path="${BASH_SOURCE[0]%/*}/modules/$module.sh"

  # 指定されたモジュールのシェルスクリプトが存在しない場合は終了
  if [[ ! -e "$module_shell_path" ]]; then
    echo "command not found $1" && exit
  fi

  # 各種設定ファイルの初期化
  Config docker_config
  $var:docker_config __constructor__ "$module" "docker"

  Config database_config
  $var:database_config __constructor__ "$module" "database"

  Config git_config
  $var:git_config __constructor__ "$module" "git"
  string -g project_domain="$1"
  string -g project_dir="$HOME/workspace/$(basename "$($var:git_config Get "remote_domain")" .git)"
  string -g docker_dir="${project_dir}/$($var:docker_config Get "dir.default")"
  string -g docker_domain="$($var:docker_config Get "domain")"
  string -g shell_type="$($var:docker_config Get "shell_type")"
fi

# 以下、alias用コマンド
# artisanコマンドをDocker環境内で実行
function executeTask() {
  local task_command="$1"

  # 引数がない場合はエラー終了
  if [[ "${#task_command}" -eq 0 ]]; then
    echo "must be param \$1(task command)"
  else
    dockerApp "$($var:shell_type)" "php artisan $task_command"
  fi
}

# キャッシュをクリアする（プロジェクトによって異なる）
function cacheClear() {
  case ${project_domain} in
           *) dockerApp "$($var:shell_type)" "php artisan route:clear 2> /dev/null && php artisan config:clear 2> /dev/null" 2> /dev/null;; # その他用キャッシュクリア
  esac
}

# Dockerコンテナを削除（クリーンアップ）
function containerRemove() {
  outputStartLog "docker clean up"
  dockerDestroy
  outputResultLog $? "docker clean up"
}

# データベースにログイン
function dockerDatabaseLogin() {
  local user
  local password
  local database
  local setting=${1:-default}
  local container=${2:-db}

  user=$($var:database_config Get "${setting}.root.user")
  password=$($var:database_config Get "${setting}.root.password")
  database=$($var:database_config Get "${setting}.database")

  dockerDB "$user" "$password" "$database" "$container"
}

# 引数（第2引数）によって処理を切り替え
case ${2} in
  "start"  ) dockerStart;;                                  # Dockerコンテナを起動
  "stop"   ) dockerStop;;                                   # Dockerコンテナを停止
  "restart") dockerReStart;;                                # Dockerコンテナを再起動
  "ssh"    ) dockerApp "$($var:shell_type)" "${*:3}";;      # DockerコンテナにSSHログイン
  "sql"    ) dockerDatabaseLogin "$3" "$4";;                # データベースにログイン
  "redis"  ) dockerRedis "$3" "${*:4}";;                    # Redisコンテナにログイン
  "log"    ) dockerLog "${3:-app}";;                        # コンテナのログを表示
  "task"   ) executeTask "${*:3}";;                         # artisanタスクを実行
  "cc"     ) cacheClear;;                                   # キャッシュをクリア
          *) echo "command not found $2" && exit;;          # 不明なコマンドの場合はエラー表示して終了
esac
