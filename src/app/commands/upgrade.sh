#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace command

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util-ume/zsh
import util-ume/gsed
import util-ume/json
import util-ume/providers
import helpers/tool/common

## DECLARATION ##
# ------------------------ #
string -g zshrc_path="$HOME/.zshrc"
string -g zshrc_original_path="$HOME/.zshrc_original"
string -g base_zshrc_original_path="$(resourceZsh)/.zshrc_original"

## MAIN ##
# ------------------------ #
function shellReLogin() {
  #  exec zsh
  local zsh_path
  zsh_path=$(command -v zsh)

  local is_exist
  is_exist=$( (ls "$zsh_path" | wc -l | sed 's/ //g')  2> /dev/null || [[ $? == 1 ]])
  if [[ "$is_exist" -ne 0 ]]; then
    $zsh_path -l
  fi
}

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

  # rbenvをアンインストール
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

  # nodenvをアンインストール
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

function upgradeZsh() {
  local back_up_path="${zshrc_original_path}_upgrade_bk"

  # zshrc_originalのバックアップを作成
  cp -r "$zshrc_original_path" "$back_up_path"

  gsDeleteLikeWord "[aA][wW][sS]" "$zshrc_original_path" "$zshrc_original_path delete aws setting"
  gsAddTargetRowNo "1" "# nomatch setting" "$zshrc_original_path"
  gsAddTargetRowNo "2" "unsetopt nomatch \n" "$zshrc_original_path"

  # ツール設定を含む場合の処理
  if [[ "${1}" == "withTool" ]]; then
    gsDeleteLikeWord "zshrc_original" "$zshrc_path" "$zshrc_path delete sorce zshrc_original. because mast be tool setting."
    upgradeTool
  fi

  $LOCAL_SETTING/src/app/commands/zsh.sh update original
}

function upgradeAlias() {
  $LOCAL_SETTING/src/app/commands/alias.sh init

  # 各モジュールの更新
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

function upgradeTool() {
  deleteTool && $LOCAL_SETTING/src/app/commands/toolInstall.sh init

  # 各モジュールの更新
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

function upgradeSSH() {
  if [[ -f ~/.ssh/known_hosts ]]; then
    rm ~/.ssh/known_hosts
  fi
}

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

case ${1} in
  "env"     ) upgradeEnv;;
  "tool"    ) upgradeTool && shellReLogin;;
  "alias"   ) upgradeAlias && shellReLogin;;
  "hooks"   ) upgradeGitHooks;;
  "test"    ) upgradeTestSetting;;
           *) (cd $LOCAL_SETTING && git checkout . && git clean -df && git checkout master && git pull origin && brew update && brew upgrade);;
esac
