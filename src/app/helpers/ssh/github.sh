namespace helpers/ssh

## IMPORT ##
# ------------------------ #
import util_ext/chmod
import helpers/ssh/common

## MAIN ##
# ------------------------ #
SSHGithub::Init() {
  local project_domain
  local ssh_key_github_dir
  local common_ssh_key_github_dir
  project_domain=$(basename "${BASH_SOURCE[0]}" .sh)
  ssh_key_github_dir="${ssh_key_dir}/github"
  common_ssh_key_github_dir="${common_ssh_key_dir}/github"

  # 鍵ディレクトリがなければ作成
  createSecretDir "$ssh_dir" "$ssh_key_github_dir"
  createSecretDir "$common_ssh_dir" "$common_ssh_key_github_dir"

  SSHGithub::ChangeKeyDir

  # 鍵ファイルの更新
  copyOfSecretDir  "$ssh_key_github_dir" "$common_ssh_key_dir"

  SSHGithub::Update
}

SSHGithub::Update() {
  local project_domain
  project_domain=$(basename "${BASH_SOURCE[0]}" .sh)

  # 鍵ディレクトリがなければ作成
  createSecretDir "$ssh_dir" "$ssh_key_github_dir"
  createSecretDir "$common_ssh_dir" "$common_ssh_key_github_dir"

  SSHGithub::ChangeKeyDir

  # 設定ファイルの更新
  updateSetting $project_domain
}

SSHGithub::CheckGitHubConnection() {
  exSSHCommand "ssh -T git@github.com"
}

SSHGithub::ChangeKeyDir() {
  local aws_key_dir="${ssh_dir}/github"
  local ssh_key_dir="${ssh_key_dir}/github"

  if [[ -d "$aws_key_dir" ]]; then
    local aws_key_path_list
    # aws_key_path_list=( $(find "$aws_key_dir" -type f -not -name "*DS_St*" -not -path "*bk*" | wc -l | sed 's/ //g') )
    aws_key_path_list=( $(find "$aws_key_dir" -type f -not -name "*DS_St*" -not -path "*bk*") )

# q
    for aws_key_path in "${aws_key_path_list[@]}"; do
      if [[ -L "$aws_key_path" ]];then
        unlink "$aws_key_path"
        copyOfSecretFile "${ssh_key_dir}/${aws_key_path##/*}" "$aws_key_path"
      fi
    done
  # rm -r "$ssh_key_dir"
    rm -rf "$ssh_key_dir"
  fi
}

alias sshGithubCleanUp='SSHGithub::Init'
alias sshGithubUpdate='SSHGithub::Update'
alias checkGitHubConnection='SSHGithub::CheckGitHubConnection'
