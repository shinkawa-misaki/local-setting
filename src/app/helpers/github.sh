namespace helpers
set -e

## IMPORT ##
# ------------------------ #
import helpers/config
import helpers/ssh/github
import util/class
import util_ext/log
import util_ext/github
import util_ext/providers

## MAIN ##
# ------------------------ #
# GitHub関連の操作をまとめたクラス
class:GitHubCommon() {
  private string config_path
  private string workspace_dir
  private string project_domain
  private Config github_config

  # コンストラクタ
  GitHubCommon.__constructor__() {
    this config_path = "$1"
    this workspace_dir = "$(this GetWorkspaceDir)"

    this github_config __constructor__ "$(this config_path)" ".git"

    this project_domain = "${2:-$(this GetProjectDomain)}"
  }

  # プロジェクトをcloneする
  GitHubCommon.Clone() {
    local git_domain
    local git_branch
    local cloneDir
    git_domain="$(this github_config Get "remote_domain")"
    git_branch="$(this github_config Get "remote_branch")"
    cloneDir="$(this GetProjectDir)"

    # GitHub接続を確認
    checkGitHubConnection

    outputStartLog "clone $git_domain project to $cloneDir"
    # プロジェクトを指定ブランチでclone
    (cd "$(this workspace_dir)" && cloneProject "$git_branch" "$git_domain" "$cloneDir")
    outputResultLog $? "clone $git_domain project to $cloneDir"
  }

  # 指定したファイルをGit管理の対象外に設定（skip-worktree）
  GitHubCommon.Skip() {
    local projectDir
    local target_dir
    projectDir="$(this GetProjectDir)"
    target_dir="${projectDir}$(this github_config Get "skip.dir")"
    local skip_file_paths=( $($var:setting GitGetConfigToArrayToString "skip.target_list") )

    for skip_file_path in "${skip_file_paths[@]}"; do
      # git skipを実行（管理対象から除外）
      outputInfoLog "git skipp $skip_file_path"
      (cd "$target_dir" && git update-index --skip-worktree "$skip_file_path")
    done
  }

  # 指定したファイルをGit管理対象に戻す（no-skip-worktree）
  GitHubCommon.NoSkip() {
    local projectDir
    local target_dir
    projectDir="$(this GetProjectDir)"
    target_dir="${projectDir}$(this github_config Get "skip.dir")"
    local skip_file_paths=( $($var:setting GitGetConfigToArrayToString "skip.target_list") )

    for skip_file_path in "${skip_file_paths[@]}"; do
      # git no-skipを実行（管理対象に復帰）
      outputInfoLog "git no-skipp $skip_file_path"
      (cd "$target_dir" && git update-index --no-skip-worktree "$skip_file_path")
    done
  }

  # ローカルリポジトリのGit hooksを設定
  GitHubCommon.LocalRepositoryHooks(){
    local source_dir="${1}/hooks"
    local project_dir
    local dest_dir
    project_dir="$(this GetProjectDir)"
    dest_dir=$(cd "$project_dir" && git rev-parse --git-dir)/hooks

    local link_path
    link_path=$(cd "$project_dir" && realpath --relative-to="$dest_dir" "$source_dir")

    for hook in $(ls -U1 "$source_dir"); do
      # hookがリンクの場合、いったん解除
      if [[ -L "$project_dir/$dest_dir/$hook" ]]; then
        (cd "$project_dir" && unlink "$dest_dir/$hook")
        echo "uninstall $hook"
      fi

      # hookをリンクとして設定
      (cd "$project_dir" && ln -s "$link_path/$hook" "$dest_dir/$hook")
      echo "install $hook"
    done
  }

  # 最新のリモートブランチを取得して現在のブランチに反映
  GitHubCommon.Latest() {
    local latest_branch="${1:-$(this GetConfig "remote_branch")}"
    local project_dir
    local local_branch
    local diff_count
    project_dir="$(this GetProjectDir)"
    local_branch="$(cd "$project_dir" && git branch --contains | sed 's/\* //g')"
    diff_count="$(cd "$project_dir" && git status | grep -E 'modified|new|deleted'| wc -l | sed 's/\* //g')"

    # 最新の情報を取得
    outputInfoLog "get latest ${project_dir##*/}"
    if [[ "$diff_count" -ne 0 ]]; then
      # 変更があればstash
      outputInfoLog "get stash save ${project_dir##*/}"
      (cd "$project_dir" && git add && git stash save)
    fi

    # 最新ブランチにcheckout
    if [[ "$local_branch" != "$latest_branch" ]]; then
      outputInfoLog "get checkout $latest_branch ${project_dir##*/}"
      (cd "$project_dir" && git checkout "$latest_branch")
    fi

    # 最新の変更をpull
    (cd "$project_dir" && git pull origin "$latest_branch")

    # 元のブランチに戻ってrebase
    if [[ "$local_branch" != "$latest_branch" ]]; then
      outputInfoLog "get checkout $local_branch ${project_dir##*/}"
      (cd "$project_dir" && git checkout "$local_branch")
      outputWarnLog "start rebase branch! ${project_dir##*/}: $local_branch"
      (cd "$project_dir" && git rebase "$latest_branch")
    fi

    # stashした変更がある場合は注意を促す
    if [[ "$diff_count" -ne 0 ]]; then
      outputWarnLog "please git stash pop ${project_dir##*/}"
    fi
  }

  # 指定キーの設定値を取得
  GitHubCommon.GetConfig() {
    local key="$1"

    this github_config Get "$key"
  }

  # 指定キーの設定値（配列）を文字列で取得
  GitHubCommon.GetConfigToArrayToString() {
    local key="$1"

    this github_config GetArrayToString "$key"
  }

  # ワークスペースディレクトリのパスを取得
  GitHubCommon.GetWorkspaceDir() {
    echo "$HOME/workspace"
  }

  # プロジェクトドメインを取得
  GitHubCommon.GetProjectDomain() {
    basename "$(this github_config Get "remote_domain")" .git
  }

  # プロジェクトディレクトリのパスを取得
  GitHubCommon.GetProjectDir() {
    local local_domain
    local_domain=$(this github_config Get "local_domain")

    if [[ -z "$local_domain" ]]; then
      local_domain=$(this project_domain)
    fi

    echo "$(this workspace_dir)/${local_domain}"
  }
}

Type::Initialize GitHubCommon
