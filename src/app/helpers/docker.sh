namespace helpers
set -e

## IMPORT ##
# ------------------------ #
import util/class
import util_ext/log
import util_ext/gsed
import util_ext/aws
import util_ext/docker
import util_ext/providers
import helpers/config
import helpers/spinner
import helpers/database/common

## MAIN ##
# ------------------------ #
# Docker操作共通クラス
class:DockerCommon() {
  private string project_domain
  private string project_dir
  private string docker_dir
  private string docker_yml_dir
  private string docker_shell_type
  private string config_path
  private Config docker_config
  private Config databse_config

  # コンストラクタ
  DockerCommon.__constructor__() {
    this project_domain = "$1"
    this project_dir = "$2"
    this config_path = "$3"
    this docker_config __constructor__ "$(this config_path)" ".docker"
    this databse_config __constructor__ "$(this config_path)" ".database"

    # Docker関連のディレクトリパスを取得
    this docker_dir = "$(this GetDockerDir)"
    this docker_yml_dir = "$(this GetDockerYmlDir)"

    this docker_shell_type = "$(this docker_config Get "shell_type")"
  }

  # プロジェクトソースをアーカイブする
  DockerCommon.ProjectArchive() {
    local log_message_main
    log_message_main="$(this project_domain) Try to archive sources"

    outputStartLog "$log_message_main"
    local archive_dir
    archive_dir="$(this docker_dir)/$(this GetDockerConfig "dir.archive")"
    # アーカイブディレクトリが存在する場合のみアーカイブ処理
    if [[ -e "$archive_dir" ]]; then
      # 最新の変更をリモートから取得
      outputStartLog "$log_message_main Fetching latest changes."
      (cd "$(this project_dir)" && git fetch)
      outputResultLog $? "$log_message_main Fetching latest changes."

      # 既存のアーカイブを削除し再作成
      outputStartLog "$log_message_main Clean up archive directory"
      (rm -rf "$archive_dir" && mkdir -p "$archive_dir")
      outputResultLog $? "$log_message_main Clean up archive directory"

      # 現在のブランチをアーカイブ化
      local tree_ish
      tree_ish=$(cd "$(this project_dir)" && git rev-parse --abbrev-ref HEAD)

      # アーカイブ作成
      outputStartLog "$log_message_main Archive sources from $(this project_dir) into $archive_dir"
      (cd "$(this project_dir)" && git archive --format=tar "$tree_ish" | tar -C "$archive_dir" -xf -)
      outputResultLog $? "$log_message_main Archive sources from $(this project_dir) into $archive_dir"
    fi
    outputResultLog $? "$log_message_main"
  }

  # Docker用.env環境設定
  DockerCommon.EnvSetting(){
    local env_path
    env_path="$(this docker_dir)/.env"
    local env_keys=( $(this GetDockerConfigKeys "env") )

    # 設定キーが存在する場合のみ設定処理を実行
    if [[ "${#env_keys[@]}" -gt 0 ]]; then
      outputStartLog "$env_path add setting"

      # .envファイルが存在しない場合、新規作成してコメントを追加
      if [[ ! -f "$env_path" ]]; then
        touch "$env_path"
        echo "# docker用の環境変数" > "$env_path"
      else
        # 既存の.envファイルにコメントを追加（重複なし）
        gsAddUniqueRow "# docker用の環境変数" "$env_path" "" "docker .env setting add comment"
      fi

      # 各環境変数を.envに設定
      for key in "${env_keys[@]}"; do
        local log_message="docker .env setting $key"

        local value
        value="$(this GetDockerConfig "env.$key")"

        # 環境変数を追記
        outputStartLog "$env_path add setting $key=$value"
        gsAddUniqueRow "$key=$value" "$env_path" "" "$log_message"
        outputResultLog $? "$env_path add setting $key=$value"
      done
      outputResultLog $? "$env_path add setting"
    fi
  }

  # ARM環境のプラットフォーム設定を追加する
  DockerCommon.PlatformSetting(){
    # TODO ymlファイルをdockerディレクトリ内に保有するようにプロジェクト全体で統一する
    # CPUアーキテクチャがarm64の場合のみ処理を行う
    if checkAppleSilicon; then
      local yaml_path
      yaml_path="$(this docker_yml_dir)/docker-compose.yml"
      local search_word="3306"
      local target_word="    platform: linux\/x86\_64 # 追加"

      #　TODO dockerのバージョンアップでversion表記がなくなったため、暫定対応
      local is_exist
      is_exist=$(less "$yaml_path" | grep -c "platform: linux" || [[ $? == 1 ]])
      if [[ "$is_exist" -eq 0 ]]; then
        gsAddUniqueRowWithTargetWord "$search_word" "$target_word" "$yaml_path"
        outputResultLog $? "docker-compose.yaml add platform"
      fi
    fi
  }

  # Dockerコンテナをビルド・起動する
  DockerCommon.ProjectBuild() {
    local env_path
    local yaml_path
    env_path="$(this docker_dir)/.env"
    yaml_path="$(this docker_yml_dir)/docker-compose.yml"

    # docker-compose.ymlのversion指定を削除（暫定対応）
    gsDeleteLikeWord "version" "$yaml_path" "docker-compose.yaml delete version"

    # TODO dockerDesktopの更新の度に必要になる...
    # Docker Desktop設定ファイルの認証設定を修正（暫定対応）
    if [[ -f "$HOME/.docker/config.json" ]]; then
      gsReplaceSudo "credsStore" "credStore" "$HOME/.docker/config.json"
    fi

    # .envファイルがあれば環境変数を指定してDockerビルド
    local result
    if [[ -f "$env_path" ]]; then
      dockerBuild --env-file "$env_path"
      result=$?
    else
      dockerBuild
      result=$?
    fi

    echo "$result"
  }

  # Dockerレジストリにログインする
  DockerCommon.Login() {
    local profile=${1}
    local user
    local password
    local registry
    user="$(this GetDockerConfig "login.user")"
    password="$(this GetDockerConfig "login.password")"
    registry="$(this GetDockerConfig "login.registry")"

    # AWS ECR認証情報を取得し、Dockerログインを実行
    awsGetEcrGetPassword "$profile" | dockerLogin "$user" "$password" "$registry"
  }

  # データベースのダンプファイルを作成する
  DockerCommon.DataBaseDump() {
    local setting="${1:-default}"
    local dump_path
    local collation
    dump_path="$(resourceDocker)/dump.sql"
    collation="$(this GetDatabaseConfig "${setting}.collation")"

    # 指定されたcollation設定でデータベースのダンプを取得
    databaseUpdate "$dump_path" "$collation"
  }

  # コンテナ内データベースへダンプをインポートする
  DockerCommon.ContainerDBImportDataBase() {
    local dump_path="$1"
    local setting="${2:-default}"
    local container="${3:-db}"
    local user
    local password
    local charset
    local database
    user=$(this GetDatabaseConfig "${setting}.root.user")
    password=$(this GetDatabaseConfig "${setting}.root.password")
    charset="$(this GetDatabaseConfig "${setting}.charset")"
    database="$(this GetDatabaseConfig "${setting}.using")"

    # ダンプファイルが存在しない場合はエラー終了
    if [[ ! -e "$dump_path" ]]; then
      outputErrorLog "$dump_path No such file or directory!"
      exit
    fi

    outputStartLog "$(this project_domain) docker container import dump.sql"
    local count=10
    local result=1
    # DBへのインポートを最大10回まで試行
    while [[ "$count" -gt 0 && "$result" -gt 0 ]]; do
      sleep 6
      dockerDB "$user" "$password" "$database" "$container" --default-character-set="$charset" < "$dump_path" 2>&1 &
       local pid=$!

       # スピナーの実行
       spinnerSetUp "$pid" "ImportDataBase" && spinnerDown "$pid"
      result=$?
      ((count--))
    done
    outputResultLog $result "$(this project_domain) docker container import dump.sql"
  }

  # ファイルをコンテナにコピー
  DockerCommon.ContainerCopyFile() {
    local log_message_main="$1"
    local local_target="$2"
    local remote_dir="$3"
    local container=${4:-app}
    local log_message="$log_message_main docker compose cp ${local_target##*/}"

    outputStartLog "$log_message"
    dockerCopy "$local_target" "$remote_dir" "$container"
    outputResultLog $? "$log_message"
  }

  # コンテナ内のファイルを削除
  DockerCommon.ContainerDeleteFile() {
    local log_message="$1"
    local remote_path="$2"
    local container_type=${3:-app}
    local container_name=${4:-app}
    local log_message="$log_message_main docker compose delete ${remote_path##*/}"

    this ContainerExecCommand "$log_message" "rm $remote_path" "$container_type" "$container_name"
  }

  # コンテナ内でコマンドを実行
  DockerCommon.ContainerExecCommand() {
    local log_message_main="$1"
    local shell_path="$2"
    local container=${3:-app}
    local log_message="$log_message_main docker compose exec ${shell_path##*/}"

    outputStartLog "$log_message"
    dockerApp "$(this docker_shell_type)" "${shell_path}" "${container}"
    outputResultLog $? "$log_message"
  }

  # APPContainer動作確認
  DockerCommon.ProjectCurlCheck() {
    local local_curl_keys=( $(this GetDockerConfigKeys "local") )

    for local_curl_key in "${local_curl_keys[@]}"; do
      local count=3
      local result=1
      local end_point
      local code
      end_point="$(this GetDockerConfig "local[$local_curl_key].end_point")"
      code=$(curl -LI $end_point -o /dev/null -w '%{http_code}\n' -s --max-time 60)

      outputStartLog "$(this project_domain) docker container app check :  url=$end_point"
      while [[ "$count" -gt 0 && "$result" -gt 0 ]]
      do
        if [[ "$code" = $(this GetDockerConfig "local[$local_curl_key].response_code") ]]; then result=0; else result=1; fi
        ((count--))
      done

      if [[ "$result" -eq 0 ]]; then
        outputInfoLog "$(this project_domain) docker container app check : code=$code success!"
      else
        outputWarnLog "$(this project_domain) docker container app check : code=$code failed!"
      fi
    done
  }

  # Dockerディレクトリを取得
  DockerCommon.GetDockerDir() {
    local docker_dir
    docker_dir=$(this GetDockerConfig "dir.default")

    if [[ ${#docker_dir} -eq 0 ]]; then
      this project_dir
    else
      echo "$(this project_dir)/${docker_dir}"
    fi
  }

  # docker-compose.ymlのディレクトリを取得
  DockerCommon.GetDockerYmlDir() {
    local docker_yml_dir
    docker_yml_dir=$(this GetDockerConfig "dir.yml")

    if [[ ${#docker_yml_dir} -eq 0 ]]; then
      this project_dir
    else
      echo "$(this project_dir)/${docker_yml_dir}"
    fi
  }

  # Dockerドメインを取得
  DockerCommon.GetDockerDomain() {
    this GetDockerConfig "domain"
  }

  # ローカルリポジトリディレクトリを取得
  DockerCommon.GetLocalRepositoryDir() {
    local target_dir
    target_dir=$(this GetDockerConfig "dir.deploy.repository")

    echo "$(this project_dir)/${target_dir}"
  }

  # コンテナのデプロイディレクトリを取得
  DockerCommon.GetRemoteDeployDir() {
    local target_dir
    target_dir=$(this GetDockerConfig "dir.deploy.container")

    echo "$(this docker_dir)/${target_dir}"
  }

  # Docker設定を取得
  DockerCommon.GetDockerConfig() {
    local key="$1"

    this docker_config Get "$key"
  }

  # データベース設定を取得
  DockerCommon.GetDatabaseConfig() {
    local key="$1"

    this databse_config Get "$key"
  }

  # Docker設定のキーを取得
  DockerCommon.GetDockerConfigKeys() {
    local key="$1"

    this docker_config GetKeys "$key"
  }
}

Type::Initialize DockerCommon
