namespace util-ext

## IMPORT ##
# ------------------------ #
import util-ext/log

## MAIN ##
# ------------------------ #
# Docker レジストリへログインする関数
Docker::Login() {
  local user="$1"
  local password="$2"
  local registry="$3"

  docker login --username "$user" --password"$password" "$registry"
}

# Docker イメージをビルドし、コンテナを起動する関数
Docker::Build() {
  outputStartLog "$project_domain docker build"
  local option="$*"
  local is_build
  is_build="$(Docker::ContainerCheck)"
  # コンテナがまだ存在しない場合のみビルドを実行する
  if [[ "$is_build" -eq 0 ]]; then
    (cd "$docker_dir" && docker compose $option up -d --build 1>&2)
    local result="$?"
    # ビルドが失敗した場合はコンテナとビルドキャッシュを削除して終了
    if [[ "$result" -ne 0 ]]; then
      Docker::Remove
      Docker::BuildCacheRemove
    fi
    outputResultLog $result "$project_domain docker build"
    exit "$result"
  else
    outputInfoLog "$project_domain is already Build"
    return 0
  fi
}

# Docker コンテナと関連するボリュームや不要なイメージを削除する関数
Docker::Remove() {
  outputStartLog "$project_domain docker remove"
  local is_build
  is_build="$(Docker::ContainerCheck)"
  # 既にコンテナが存在する場合のみ削除処理を実行する
  if [[ "$is_build" -ne 0 ]]; then
    local is_paused
    local is_exit
    is_paused="$(Docker::ContainerCheck "Paused")"
    is_exit="$(Docker::ContainerCheck "Exit")"
    # コンテナが一時停止の場合は再開、終了状態の場合は開始する
    if [[ "$is_paused" -ne 0 ]]; then
      (cd "$docker_dir" && docker compose unpause)
    elif [[ "$is_exit" -ne 0 ]]; then
      (cd "$docker_dir" && docker compose start)
    else
      outputInfoLog "$project_domain is already Up"
    fi
    (cd "$docker_dir" && docker compose down --volumes --remove-orphans 1>&2 && docker image prune -a -f 1>&2)
  fi
  outputResultLog $? "$project_domain docker remove"
}

# Docker のビルドキャッシュを削除する関数
Docker::BuildCacheRemove() {
  outputStartLog "$project_domain docker builder prune"
  docker builder prune -a -f 1>&2
  outputResultLog $? "$project_domain docker builder prune"
}

# Docker ディレクトリがあれば削除し、ビルドキャッシュも削除する関数
Docker::Destroy() {
  # $docker_dir が存在する場合のみ削除する
  if [[ -e $docker_dir ]]; then
    Docker::Remove
  fi
  Docker::BuildCacheRemove
}

# Docker の全システム要素を削除する関数
Docker::ALLDestroy() {
  docker system prune -f
  docker container prune -f
  docker image prune -a -f
  docker volume prune -f
  docker network prune -f
}

# Docker コンテナを開始する関数
Docker::Start() {
  local is_build
  is_build="$(Docker::ContainerCheck)"
  # コンテナが存在しない場合はエラー
  if [[ "$is_build" -eq 0 ]]; then
    outputErrorLog "must be $project_domain is Build"
  fi

  local is_paused
  local is_exit
  is_paused="$(Docker::ContainerCheck "Paused")"
  is_exit="$(Docker::ContainerCheck "Exit")"
  # 一時停止の場合は再開、終了状態の場合は起動
  if [[ "$is_paused" -ne 0 ]]; then
    (cd "$docker_dir" && docker compose unpause)
  elif [[ "$is_exit" -ne 0 ]]; then
    (cd "$docker_dir" && docker compose start)
  else
    outputInfoLog "$project_domain is already Up"
  fi

  # コマンドが失敗した場合にはコンテナを停止する
  if [[ "$?" -ne 0 ]]; then
    (cd "$docker_dir" && docker compose stop)
  fi
}

# Docker コンテナを停止する関数
Docker::Stop() {
  local is_build
  is_build="$(Docker::ContainerCheck)"
  # コンテナが存在しない場合はエラー
  if [[ "$is_build" -eq 0 ]]; then
    outputErrorLog "must be $project_domain is Build"
  fi

  local is_up
  is_up="$(Docker::ContainerCheck "Up")"
  # 起動中の場合のみ一時停止する
  if [[ "$is_up" -ne 0 ]]; then
    (cd "$docker_dir" && docker compose pause)
  else
    outputInfoLog "$project_domain is already Paused"
  fi
}

# Docker コンテナを再起動する関数
Docker::ReStart() {
  local is_build
  is_build=$(Docker::ContainerCheck "$docker_domain")
  # コンテナが存在しない場合はエラー
  if [[ "$is_build" -eq 0 ]]; then
    outputErrorLog "must be $project_domain is Build"
  fi

  (cd "$docker_dir" && docker compose restart)
}

# Docker コンテナが存在するか、指定したステータスかどうかをチェックする関数
Docker::ContainerCheck() {
  local status="$1"

  if [[ "$status" == "" ]]; then
    (cd "$docker_dir" && docker compose ps -a | grep -c "$docker_domain" || [[ $? == 1 ]])
  else
    (cd "$docker_dir" && docker compose ps -a | grep "$docker_domain" | grep -c "$status" || [[ $? == 1 ]])
  fi
}

# 指定したコンテナが存在するかを確認する関数
Docker::ContainerExist() {
  local container="$1"

  local is_build
  is_build="$(Docker::ContainerCheck)"
  # コンテナが存在しない場合はエラー
  if [[ "$is_build" -eq 0 ]]; then
    outputErrorLog "must be $project_domain is Build" && exit
  fi

  local is_paused
  is_paused="$(Docker::ContainerCheck "Paused")"
  # コンテナが一時停止中なら再開
  if [[ "$is_paused" -ne 0 ]]; then
    (cd "$docker_dir" && docker compose unpause)
  fi

  local is_exit
  is_exit="$(Docker::ContainerCheck "Exit")"
  # コンテナが終了状態なら起動
  if [[ "$is_exit" -ne 0 ]]; then
    (cd "$docker_dir" && docker compose start)
  fi

  (cd $docker_dir && docker compose ps | grep "$docker_domain" | grep -c "$container" || [[ $? == 1 ]])
}

# 以下便利機能
# コンテナのログを表示する関数
Docker::Log() {
  local container="$1"

  local is_start
  is_start=$(Docker::ContainerExist "$container")
  # コンテナが稼働中でない場合はエラー
  if [[ "$is_start" -eq 0 ]]; then
    outputErrorLog "can not start $container"
  else
    (cd "$docker_dir" && docker compose logs $container --follow)
  fi
}

# コンテナ内でコマンドを実行する関数
Docker::Exec() {
  local container="$1"

  local is_start
  is_start=$(Docker::ContainerExist "$container")
  # コンテナが稼働中でない場合はエラー
  if [[ "$is_start" -eq 0 ]]; then
    outputErrorLog "can not start $container"
    exit
  else
    (cd "$docker_dir" && docker compose exec "$@")
  fi
}

# コンテナ内で対話形式のコマンドを実行する関数
Docker::CommandExec() {
  local container="$1"

  local is_start
  is_start=$(Docker::ContainerExist "$container")
  # コンテナが稼働中でない場合はエラー
  if [[ "$is_start" -eq 0 ]]; then
    outputErrorLog "can not start $container of $docker_dir"
    exit
  else
    outputInfoLog "docker compose exec -it $@"
    (cd "$docker_dir" && docker compose exec -it "$@")
  fi
}

# コンテナを一時起動してコマンドを実行し終了する関数
Docker::CommandRun() {
  (cd "$docker_dir" && docker compose run --rm "$@")
}

# ホストのファイルをコンテナへコピーする関数
Docker::Copy() {
  local local_path="$1"
  local target_dir="$2"
  local container=${3:-app}

  local is_start
  is_start=$(Docker::ContainerExist "$container")
  # コンテナが稼働中でない場合は起動する
  if [[ "$is_start" -eq 0 ]]; then
    Docker::Start
  fi

  (cd "$docker_dir" && docker compose cp "$local_path" "$container":"$target_dir")
}

# コンテナに MySQL データベースへ接続/クエリ実行をする関数
Docker::DB() {
  local db_user="$1"
  local db_pass="$2"
  local db_database="$3"
  local container=${4:-db}
  local command="${*:5}"

  # command が指定されている場合はコマンド実行、指定がない場合は対話形式で接続
  if [[ ${#command} -ne 0 ]]; then
    Docker::CommandExec $container mysql -u$db_user -p$db_pass $db_database "$command"
  else
    Docker::Exec $container mysql -u$db_user -p$db_pass $db_database
  fi
}

# コンテナ内で指定したシェルを使用してコマンド実行または対話起動する関数
Docker::App() {
  local shell_type="$1"
  local command="$2"
  local container="${3:-app}"

  # command が指定されている場合はコマンド実行、指定がない場合はシェル起動
  if [[ ${#command} -ne 0 ]]; then
    Docker::CommandExec $container $shell_type -c "$command"
  else
    Docker::Exec $container $shell_type
  fi
}

# Redis コンテナで CLI を実行する関数 (m/e/redis の3パターン)
Docker::Redis() {
  local type="$1"
  local command="$2"

  case ${type} in
    "m") local container="multipurpose";;
    "e") local container="ext_data";;
      *) local container="redis";;
  esac

  # command が指定されている場合はコマンド実行、指定がない場合は対話形式で CLI を起動
  if [[ ${#command} -ne 0 ]]; then
    Docker::CommandExec $container redis-cli --raw "$command"
  else
    Docker::Exec $container redis-cli
  fi
}

alias dockerLogin='Docker::Login'
alias dockerBuild='Docker::Build'
alias dockerRemove='Docker::Remove'
alias dockerBuildCacheRemove='Docker::BuildCacheRemove'
alias dockerDestroy='Docker::Destroy'
alias dockerALLDestroy='Docker::ALLDestroy'
alias dockerStart='Docker::Start'
alias dockerStop='Docker::Stop'
alias dockerReStart='Docker::ReStart'
alias dockerLog='Docker::Log'
alias dockerCopy='Docker::Copy'
alias dockerDB='Docker::DB'
alias dockerApp='Docker::App'
alias dockerRedis='Docker::Redis'
