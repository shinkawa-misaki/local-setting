#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace command

# ==============================================================================
# upgrade.sh
# · 各種設定（zsh／alias／tool／SSH／env／hooks／test）の
#   アップグレード／初期化をまとめて行うエントリースクリプト
# ==============================================================================

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util_ext/zsh
import util_ext/gsed
import util_ext/json
import util_ext/providers
import helpers/tool/common

## DECLARATION ##
# ------------------------ #
string -g zshrc_path="$HOME/.zshrc"
string -g zshrc_original_path="$HOME/.zshrc_original"
string -g base_zshrc_original_path="$(resourceZsh)/.zshrc_original"

## MAIN ##
#  zsh がインストールされていれば、再ログインして最新設定を反映する

#=============================================================
#function shellRelohin() {
# if command -v zsh >/dev/null 2>&1; then
#   zsh -l
# fi
#}
# これでまとまるかな？？ls,wc,sedなしで書けそうな気がしています。。。
#=============================================================
# ------------------------ #
function shellReLogin() {
  local zsh_path
  zsh_path=$(command -v zsh)

  local is_exist
  is_exist=$( (ls "$zsh_path" | wc -l | sed 's/ //g')  2> /dev/null || [[ $? == 1 ]])
  if [[ "$is_exist" -ne 0 ]]; then
    $zsh_path -l
  fi
}


#=============================================================
# toolUnInstall "app" "Coccinellida"           "brew uninstall coccinellida"
# toolUnInstall "app" "Alfred 5"               "brew uninstall alfred"
# toolUnInstall "brew" "sequel-pro-nightly"    "brew uninstall sequel-pro-nightly"
# toolUnInstall "brew" "sequel-pro"            "brew uninstall --cask sequel-pro"
#
#こうするとシンプルになって文字列リテラルをそのまま第三引数として渡せる？？かな？？
#=============================================================
#　アプリ／ツール／環境設定をまとめてアンインストール
function deleteTool() {
  local etc_dir
  etc_dir="$(brew --prefix)/etc"

  # coccinellidaをアンインストール
  local unInstallCommand="brew uninstall coccinellida"
  toolUnInstall "app" "Coccinellida" "$unInstallCommand"

  # brew caskをアンインストール
  local unInstallCommand="brew uninstall alfred"
  toolUnInstall "app" "Alfred 5" "$unInstallCommand"

  # SequelProをアンインストール
  local unInstallCommand="brew uninstall sequel-pro-nightly"
  toolUnInstall "brew" "sequel-pro-nightly" "$unInstallCommand"

  local unInstallCommand="brew uninstall --cask sequel-pro"
  toolUnInstall "brew" "sequel-pro" "$unInstallCommand"



  local etc_dir
  etc_dir="$(brew --prefix)/etc"

  # rbenv の設定ディレクトリがあれば削除
  if [[ $(toolIsExist "brew" "rbenv") -ne 0 ]]; then
    if [[ -d "${etc_dir}/rbenv.d" ]]; then
      sudo rm -rf "${etc_dir}/rbenv.d"
    fi
    if [[ -d ~/.rbenv ]]; then
      sudo rm -rf ~/.rbenv
    fi
  fi

  zshrcDeleteWord "rbenv"
  local unInstallCommand="brew uninstall --ignore-dependencies rbenv"
  toolUnInstall "brew" "rbenv" "$unInstallCommand"

  # nodenv の設定ディレクトリがあれば削除
  if [[ $(toolIsExist "brew" "nodenv") -ne 0 ]]; then
    if [[ -d "$etc_dir/nodenv.d" ]]; then
      sudo rm -rf "${etc_dir}/nodenv.d"
    fi
    if [[ -d ~/.nodenv ]]; then
      sudo rm -rf ~/.nodenv
    fi
  fi

  zshrcDeleteWord "nodenv"
  local unInstallCommand="brew uninstall nodenv"
  toolUnInstall "brew" "nodenv" "$unInstallCommand"
}

# .zshrc_original をバックアップし、nomatch 設定を挿入
# withTool オプションでツール設定も更新
function upgradeZsh() {
  local back_up_path="${zshrc_original_path}_upgrade_bk"

  # zshrc_originalのバックアップを作成
  cp -r "$zshrc_original_path" "$back_up_path"

# AWS 関連設定を削除し、nomatch オプションを追加
  gsDeleteLikeWord "[aA][wW][sS]" "$zshrc_original_path" "$zshrc_original_path delete aws setting"
  gsAddTargetRowNo "1" "# nomatch setting" "$zshrc_original_path"
  gsAddTargetRowNo "2" "unsetopt nomatch \n" "$zshrc_original_path"

# withTool 指定ならツール設定を先にアップグレード
  if [[ "${1}" == "withTool" ]]; then
    gsDeleteLikeWord "zshrc_original" "$zshrc_path" "$zshrc_path delete sorce zshrc_original. because mast be tool setting."
    upgradeTool
  fi

  # alias やツール更新を反映した後に更新
  $LOCAL_SETTING/src/app/commands/zsh.sh update original
}


# alias 設定を再初期化し、各モジュールの alias を更新
function upgradeAlias() {

  # alias本体を初期化
  $LOCAL_SETTING/src/app/commands/alias.sh init

  # 設定ディレクトリ内の各モジュール設定を確認してalias 更新を実行する。
  find "$(configDir)" -type f | while read -r json_path; do
    local module_domain
    module_domain="$(basename "$(jsonGetValue "$json_path" ".git.remote_domain")" .git)"
    if [[ -d "$HOME/workspace/$module_domain" ]]; then
      local module
      module="$(gsEscapeKebab "$module_domain")"

      $LOCAL_SETTING/src/app/commands/modules/$module.sh update alias
    fi
  done
}

# deleteTool → toolInstall 初期化 → 各モジュールのツール更新
function upgradeTool() {
  deleteTool && $LOCAL_SETTING/src/app/commands/toolInstall.sh init

  # 各モジュールごとにツール設定を更新する。
  find "$(configDir)" -type f | while read -r json_path; do
    local module_domain
    module_domain="$(basename "$(jsonGetValue "$json_path" ".git.remote_domain")" .git)"
    if [[ -d "$HOME/workspace/$module_domain" ]]; then
      local module
      module="$(gsEscapeKebab "$module_domain")"

      $LOCAL_SETTING/src/app/commands/modules/$module.sh update tool
    fi
  done
}


#=============================================================
# [[ -f ~/.ssh/known_hosts ]] && zrm ~/.ssh/known_hosts
# こんな風に１行に出来そうです。(っ*'ω'*c)
#=============================================================
#   SSH known_hosts を削除して再生成を促してる？？
function upgradeSSH() {
  if [[ -f ~/.ssh/known_hosts ]]; then
    rm ~/.ssh/known_hosts
  fi
}

# 各モジュールの環境変数設定を更新なのでupgradeEnv
function upgradeEnv() {
  # 各モジュールの更新
  find "$(configDir)" -type f | while read -r json_path; do
    local module_domain
    module_domain="$(basename "$(jsonGetValue "$json_path" ".git.remote_domain")" .git)"
    if [[ -d "$HOME/workspace/$module_domain" ]]; then
      local module
      module="$(gsEscapeKebab "$module_domain")"
      $LOCAL_SETTING/src/app/commands/modules/$module.sh update env
    fi
  done
}

# 各モジュールの GitHooks設定を更新
function upgradeGitHooks() {
  # 各モジュールの更新
  find "$(configDir)" -type f | while read -r json_path; do
    local module_domain
    module_domain="$(basename "$(jsonGetValue "$json_path" ".git.remote_domain")" .git)"
    if [[ -d "$HOME/workspace/$module_domain" ]]; then
      local module
      module="$(gsEscapeKebab "$module_domain")"
      $LOCAL_SETTING/src/app/commands/modules/$module.sh update hooks
    fi
  done
}


#=============================================================
# zshrcDeleteWord "anyenv"
# toolUnInstall　"brew" "anyenv" "brew uninstall anyenv"
#
# [[ -d $etc_dir/anyenv.d ]] && sudo rm -rf $etc_dir/anyenv.d
# [[ -d ~/.anyenv ]]         && sudo rm -rf ~/.anyenv
# shellReLogin
# }
#ここもこんな感じにまとめてみたいです。。。
#=============================================================
#　テスト環境設定をリセット＆anyenv 関連をアンインストール
function upgradeTestSetting() {
  # anyenvをアンインストール
  zshrcDeleteWord "anyenv"
  local unInstallCommand="brew uninstall anyenv"
  toolUnInstall "brew" "anyenv" "$unInstallCommand"

  if [[ -d $etc_dir/anyenv.d ]]; then
    sudo rm -rf $etc_dir/anyenv.d
  fi
  if [[ -d ~/.anyenv ]]; then
    sudo rm -rf ~/.anyenv
  fi

  shellReLogin
}

#=============================================================
#   (cd $LOCAL_SETTING \
#     && git checkout . \
#     && git clean -df \
#     && git checkout master \
#     && git pull origin \
#     && brew update \
#     && brew upgrade)
#   ;;
# esac
#最後の*)の部分が長すぎると感じたのでこの様にして見やすくしてみたいと。。。どうかな？？
#=============================================================
# 引数に応じて各アップグレード function を呼び出す
case ${1} in
  "env"     ) upgradeEnv;;
  "tool"    ) upgradeTool && shellReLogin;;
  "alias"   ) upgradeAlias && shellReLogin;;
  "hooks"   ) upgradeGitHooks;;
  "test"    ) upgradeTestSetting;;
           *) (cd $LOCAL_SETTING && git checkout . && git clean -df && git checkout master && git pull origin && brew update && brew upgrade);;
esac
