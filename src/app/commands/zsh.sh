#!/usr/bin/env bash
set -e

## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace command

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util-ume/log
import util-ume/zsh
import util-ume/chmod
import util-ume/providers
import helpers/zsh

## DECLARATION ##
# ------------------------ #
string -g zshrc_path="$HOME/.zshrc"
string -g zprofile_path="$HOME/.zprofile"
string -g zshrc_original_path="$HOME/.zshrc_original"
string -g base_zprofile_path="$(resourceZsh)/.zprofile"
string -g base_zshrc_original_path="$(resourceZsh)/.zshrc_original"

## MAIN ##
# ------------------------ #
string -g zsh_path=in_dir="$(brew --prefix)/bin/zsh"

# zsh環境をクリーンアップ（再インストールを実行）
function cleanUp() {
  unInstallZsh
  installZsh
  zshrcOriginalInit
  setZprofile
}

# zshをアンインストールする
function remove() {
  unInstallZsh
}

# パスフレーズを更新する
function updatePassPhrase() {
  zshrcOriginalReplaceWordOfRegExp "PASS_PHRASE=.*$" "PASS_PHRASE=@PASS_PHRASE@"
  setPassPhrase
}

# GitHubトークンを更新する
function updateGithubToken() {
  zshrcOriginalReplaceWordOfRegExp "GITHUB_TOKEN=.*$" "GITHUB_TOKEN=@GITHUB_TOKEN@"
  setGithubToken
}

# LDAPパスワードを更新する
function updateLdapPass() {
  zshrcOriginalReplaceWordOfRegExp "LDAP_STG_PASS=.*$" "LDAP_STG_PASS=@LDAP_STG_PASS@"
  zshrcOriginalReplaceWordOfRegExp "LDAP_PRD_PASS=.*$" "LDAP_PRD_PASS=@LDAP_PRD_PASS@"
  setLdapPass
}

# LDAPユーザーを更新する
function updateLdapUser() {
  zshrcOriginalReplaceWordOfRegExp "LDAP_USER=.*$" "LDAP_USER=@LDAP_USER@"
  setLdapUser
}

# 第一引数が「init」の場合、zsh環境を初期化
if [[ "${1}" = "init" ]]; then
  cleanUp
fi

# 第一引数が「update」の場合、第二引数に応じた更新処理を実行
if [[ "${1}" = "update" ]]; then
  case ${2} in
          "look") outputSettingZsh;;
          "ldap") updateLdapPass;;           # LDAPパスワード更新
        "github") updateGithubToken;;        # GitHubトークン更新
      "original") zshrcOriginalInit;;        # zshrcオリジナルを初期化
    "passPhrase") updatePassPhrase;;         # パスフレーズ更新
        "source") zshrcAddSourceFile "${3}";; # 指定ファイルをsourceとして追加
               *) echo "command $2 not found";; # 無効なコマンド時はメッセージ表示
  esac
fi

# 第一引数が「delete」の場合、指定された単語をzshrcから削除
if [[ "${1}" = "delete" ]]; then
  zshrcOriginalDeleteWord "${2}"
fi

# 第一引数が「clean」の場合、zshをアンインストール
if [[ "${1}" = "clean" ]]; then
  remove
fi
