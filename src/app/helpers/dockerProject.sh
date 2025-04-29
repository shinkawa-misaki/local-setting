namespace helpers
set -e

## IMPORT ##
# ------------------------ #
import util/class
import util_ext/log
import util_ext/docker
import util_ext/providers
import helpers/yml
import helpers/env
import helpers/alias
import helpers/github
import helpers/docker
import helpers/config
# ------------------------ #

# Dockerプロジェクト管理クラス
class:DockerProject() {
  private string project_name
  private string project_domain
  private string project_dir
  private string project_docker_dir
  private string project_resource_dir
  private string project_config_path
  private GitHubCommon github_common
  private DockerCommon docker_common
  private EnvCommon env_common
  private YmlCommon yml_common

  # コンストラクタ
  DockerProject.__constructor__() {
    this project_name = "$1"
    this project_domain = "$2"
    this project_config_path = "$(configDir)/$(this project_name).json"

    this github_common __constructor__ "$(this project_config_path)" "$(this project_domain)"

    # プロジェクトドメインが未指定の場合は設定ファイルから取得
    if [[ -z $(this project_domain) ]]; then
      this project_domain = "$(this GetProjectDomain)"
    fi

    this project_dir = "$(this GetProjectDir)"
    this project_resource_dir = "$(resourceModules)/$(this project_name)"

    this docker_common __constructor__ "$(this project_domain)" "$(this project_dir)" "$(this project_config_path)"

    this env_common __constructor__ \
      "$(this project_domain)" \
      "$(this project_dir)" \
      "$(this project_resource_dir)" \
      "$(this project_config_path)"
  }

  # プロジェクトを完全に削除（Docker環境を含む）
  DockerProject.DeleteProject() {
    outputStartLog "$(this project_domain) clean up project"

    # プロジェクトディレクトリが存在する場合はDocker環境とディレクトリを削除
    if [[ -e "$(this project_dir)" ]]; then
      dockerDestroy
      rm -rf "$(this project_dir)"
    fi

    # プロジェクト用aliasを削除
    aliasDeleteWord "$(this project_domain)"
    if [[ -e "$HOME/.alias_$(this project_domain)" ]]; then
      rm -rf "$HOME/.alias_$(this project_domain)"
    fi

    # Dockerのビルドキャッシュを削除
    dockerBuildCacheRemove
    outputResultLog $? "$(this project_domain) clean up project"
  }

  # GitHubリポジトリをクローン
  DockerProject.GitClone() {
    this github_common Clone
  }

  # GitHubリポジトリの最新の状態を取得
  DockerProject.Latest() {
    this github_common Latest
  }

  # Git管理対象から指定ファイルを除外（skip-worktree）
  DockerProject.GitSkip() {
    this github_common Skip
  }

  # Git管理対象外設定を解除（no-skip-worktree）
  DockerProject.GitNoSkip() {
    this github_common NoSkip
  }

  # ローカルリポジトリ用のGitフックを設定
  DockerProject.GitLocalRepositoryHooks() {
    local project_dir="$1"
    this github_common LocalRepositoryHooks "$(this project_resource_dir)" "$project_dir"
  }

  # ソースコードをアーカイブする
  DockerProject.Archive() {
    this docker_common ProjectArchive
  }

  # 環境設定(.env)をデフォルトおよびテスト用として登録・反映
  DockerProject.EnvSetting() {
    this env_common SettingDefault
    this env_common SettingTesting
  }

  # 環境設定ファイル(.env)を更新して反映（DB設定も含む）
  DockerProject.UpdateEnvSetting() {
    case ${1} in
        "db") this env_common SettingDBWithTarget "$2";; # DB設定更新
           *) this EnvSetting;;                          # デフォルト環境設定
    esac
    this ContainerAPPExecInitShellEnv
  }

  # 環境設定(.yml)をデフォルトおよびテスト用として登録・反映
  DockerProject.YMLSetting() {
    this yml_common SettingDefault
  }

  # 環境設定ファイル(yml)を更新して反映（DB設定も含む）
  DockerProject.UpdateYMLSetting() {
    local yml_target="${1:-shopping}"
    local setting_target="${2:-local_connect}"

    this yml_common SetKeyValueOfConfig "$yml_target" "$setting_target"
    this ContainerAPPExecInitShellYML
  }

  # プロジェクト専用aliasを設定
  DockerProject.AliasSet() {
    local base_alias_path
    base_alias_path="$(this project_resource_dir)/.alias_$(this project_domain)"

    # alias設定を反映
    setAlias "$base_alias_path"
  }

  # ローカルソースファイルをDockerコンテナへデプロイ
  DockerProject.DeployLocalSrcFile() {
    local local_repository_dir
    local deploy_container_dir
    local_repository_dir="$(this docker_common GetLocalRepositoryDir)"
    deploy_container_dir="$(this docker_common GetRemoteDeployDir)"

    outputStartLog "local deploy src file $local_repository_dir -> $deploy_container_dir"
    cp -rf "$local_repository_dir" "$deploy_container_dir"
    outputResultLog $? "local deploy src file $local_repository_dir -> $deploy_container_dir"
  }

  # Dockerコンテナをビルド・起動・初期化
  DockerProject.ContainerBuild() {
    this docker_common EnvSetting
    this docker_common PlatformSetting

    echo "$(this docker_common ProjectBuild)"
  }

  # Dockerコンテナを再構築
  DockerProject.ContainerReBuild() {
    dockerDestroy

    echo "$(this ContainerBuild)"
  }

  # Dockerコンテナの初期化（DBインポート含む）
  DockerProject.ContainerInitialize() {
    local dump_path="$1"
    local setting="${2:-default}"
    local container="${3:-db}"

    this ImportDataBase "$dump_path" "$setting" "$container"

    if [[ $? -eq 0 ]]; then
      this ContainerAPPExecInitShell && \
      this ContainerAPPExecInitShellEnv
    else
      exit 1
    fi
  }

  # データベースにdump.sqlをインポートする
  DockerProject.ImportDataBase() {
    local dump_path="${1:-$(resourceDocker)/dump.sql}"
    local setting="${2:-default}"
    local container="${3:-db}"

    # DBコンテナならダンプを取得
    if [[ "$container" == "db" ]]; then
      outputStartLog "DataBaseDump"
      this docker_common DataBaseDump
    fi

    # データベースインポートを非同期で実行
    this docker_common ContainerDBImportDataBase "$dump_path" "$setting" "$container"
  }

  # APPコンテナで初期化シェルを実行
  DockerProject.ContainerAPPExecInitShell() {
    local remote_dir="/root"
    local shell_path
    shell_path="$(resourceDocker)/scripts/init-local.sh"

    # コンテナ内で初期化シェルを実行
    this ExecUploadShell "$(this project_domain) app init shell" "$shell_path" "$remote_dir"
  }

  # APPコンテナで.env設定初期化シェルを実行
  DockerProject.ContainerAPPExecInitShellEnv() {
    local remote_dir="/root"
    local shell_path
    shell_path="$(resourceDocker)/scripts/init-env-local.sh"

    # コンテナ内で.env初期化シェルを実行
    this ExecUploadShell "$(this project_domain) app init shell env" "$shell_path" "$remote_dir"
  }

  # APPコンテナで.yml設定初期化シェルを実行
  DockerProject.ContainerAPPExecInitShellYML() {
    local remote_dir="/root"
    local shell_path
    shell_path="$(resourceDocker)/scripts/init-yml-local.sh"

    # コンテナ内でyml初期化シェルを実行
    this ExecUploadShell "$(this project_domain) app init shell yml" "$shell_path" "$remote_dir"
  }

  # シェルスクリプトをコンテナへアップロードして実行
  DockerProject.ExecUploadShell() {
    local log_message_main="$1"
    local shell_path="$2"
    local target_dir="$3"
    local container=${4:-app}
    local args="${*:5}"

    outputStartLog "$log_message_main"
    this docker_common ContainerCopyFile "$log_message_main" "$shell_path" "$target_dir" "$container" && \
    this docker_common ContainerExecCommand "$log_message_main" "$target_dir/${shell_path##*/}" "$container" "$args"
    this docker_common ContainerDeleteFile "$log_message_main" "$target_dir/${shell_path##*/}" "$container"
    outputResultLog $? "$log_message_main"
  }

  # Dockerレジストリにログイン
  DockerProject.DockerLogin() {
    this docker_common Login
  }

  # プロジェクトの動作確認を実施（curl接続テスト）
  DockerProject.ProjectCurlCheck() {
    this docker_common ProjectCurlCheck
  }

  # Gitの設定値を取得する
  DockerProject.GitGetConfig() {
    local key="$1"
    this github_common GetConfig "$key"
  }

  # Gitの設定値を文字列で取得
  DockerProject.GitGetConfigToArrayToString() {
    local key="$1"
    this github_common GetConfigToArrayToString "$key"
  }

  # ワークスペースのディレクトリパスを取得する
  DockerProject.GetWorkspaceDir() {
    this github_common GetWorkspaceDir
  }

  # プロジェクトのカレントディレクトリパスを取得する
  DockerProject.GetProjectDir() {
    this github_common GetProjectDir
  }

  # プロジェクトのリソースディレクトリパスを取得する
  DockerProject.GetResourceDir() {
    this project_resource_dir
  }

  # プロジェクトで使用するDockerディレクトリパスを取得する
  DockerProject.GetDockerDir() {
    this docker_common GetDockerDir
  }

  # プロジェクトドメインを取得する
  DockerProject.GetProjectDomain() {
    this github_common GetProjectDomain
  }

  # Dockerコンテナ用のドメインを取得する
  DockerProject.GetDockerDomain() {
    this docker_common GetDockerDomain
  }
}

Type::Initialize DockerProject
