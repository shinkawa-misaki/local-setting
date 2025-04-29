# 引数があれば、環境設定スクリプト（localSetting.sh）を引数付きで実行
# 引数がなければ、環境設定ディレクトリ（$LOCAL_SETTING）を単に開くだけ

function localSetting() {
 if [ "${#@}" -ne 0 ]; then
  $LOCAL_SETTING/localSetting.sh "$@"
 else
  $LOCAL_SETTING
 fi
}

# 現在のブランチ名を取得
# dev ブランチに切り替えて最新をプル
# 元のブランチに戻って dev をベースにリベース
function rebaseDev() {
  branch=$(git branch --contains | sed 's/\* //g')
  git checkout dev && git pull origin dev && git checkout ${branch} && git rebase dev
}


# rebaseDev() と同様の手順を、master ブランチに対して行う
function rebaseMaster() {
  branch=$(git branch --contains | sed 's/\* //g')
  git checkout master && git pull origin master && git checkout ${branch} && git rebase master
}


# PHP がインストールされていない場合は、localSetting update … tool で自動導入
# 現在の PHP バージョンを取得
# 目標バージョンと異なれば、Homebrew を使って該当バージョンへ切り替え
function phpenv() {
  local module_domain=$1
  local target_php_version=$2

  type php >/dev/null 2>&1
  if [[ $? -eq 1 ]]; then
    localSetting update ${module_domain} tool
  fi

  local current_php_version="$(php --version | head -n 1 | cut -d " " -f 2)"

  if [[ "$current_php_version" != "$target_php_version" ]]; then
    local arch_type
    local is_rosetta
    arch_type=$(arch)
    is_rosetta=$(sysctl -in sysctl.proc_translated 2>/dev/null)

    local php_dir="$(brew --prefix)/bin/php"

    if [[ "$(echo $current_php_version | cut -c 1)" == "8" && -L $php_dir ]]; then
      (unlink $php_dir && brew unlink php@${target_php_version} && brew link --overwrite php@${target_php_version}) 1&> /dev/null
    else
      (brew unlink php && brew unlink php@${target_php_version} && brew link --overwrite php@${target_php_version}) 1&> /dev/null
    fi
  fi
}

# 指定名の Python 仮想環境ディレクトリを $HOME/venv/… に作成（存在しない場合のみ）
#そのまま activate して有効化
function venvUp() {
  local venv_name="venv/$1"
  local venv_dir="$HOME/$venv_name"

  # Python 仮想環境（venv）の作成
  if [[ ! -e "$venv_dir" ]]; then
    (cd $HOME && python3 -m venv $venv_name)
  fi

  # Python 仮想環境（venv）の起動
  . $venv_dir/bin/activate
}

# 現在アクティブな Python 仮想環境をただちに解除
function venvDown() {
  deactivate
}
