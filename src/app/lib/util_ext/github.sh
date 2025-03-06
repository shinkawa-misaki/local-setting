namespace util-ume/github

## IMPORT ##
# ------------------------ #
# no dependencies
# ------------------------ #

## MAIN ##
# ------------------------ #
# GitHub リポジトリを指定ブランチでクローンする関数
GitHub::CloneProject() {
  local branch="$1"
  local domain="$2"
  shift; shift;

  # 追加の引数がない場合は単純にクローンを実行する
  if [[ ${#@} -eq 0 ]]; then
    git clone -b "$branch" "git@github.com:$domain"
  else
    eval "git clone -b $branch git@github.com:$domain $@"
  fi
}

# 現在のブランチに対して dev ブランチを取り込みリベースする関数
GitHub::RebaseDev() {
  branch=$(git branch --contains | sed 's/\* //g')
  git checkout dev && git pull && git checkout $branch && git rebase dev
}

# 現在のブランチに対して master ブランチを取り込みリベースする関数
GitHub::RebaseMaster() {
  branch=$(git branch --contains | sed 's/\* //g')
  git checkout master && git pull && git checkout $branch && git rebase master
}

alias cloneProject='GitHub::CloneProject'
alias rebaseDev='GitHub::RebaseDev'
alias rebaseMaster='GitHub::RebaseMaster'
