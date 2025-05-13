#!/usr/bin/env bash
set -e


#==================================================
#zsh環境設定スクリプト
#===================================================
## BOOTSTRAP ##
source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"

namespace commands

## IMPORT ##
# ------------------------ #
import util/type
import util/exception
import util_ext/log
import util_ext/zsh
import util_ext/chmod
import util_ext/providers
import helpers/zsh

## DECLARATION ##
# スクリプト全体で使うパスをグローバル変数として宣言してっちゃる。
# ------------------------ #
string -g zshrc_path="$HOME/.zshrc"
string -g zprofile_path="$HOME/.zprofile"
string -g zshrc_original_path="$HOME/.zshrc_original"
string -g base_zprofile_path="$(resourceZsh)/.zprofile"
string -g base_zshrc_original_path="$(resourceZsh)/.zshrc_original"

## MAIN ##
# ------------------------ #
string -g zsh_path=in_dir="$(brew --prefix)/bin/zsh"

#　zsh 環境を再インストールして初期状態に戻す
function cleanUp() {
  unInstallZsh
  installZsh
  zshrcOriginalInit
  setZprofile
}

# zshをアンインストールのみ行う。
function remove() {
  unInstallZsh
}

# .zshrc_original 内の PASS_PHRASE を置き換えて再設定
function updatePassPhrase() {
  zshrcOriginalReplaceWordOfRegExp "PASS_PHRASE=.*$" "PASS_PHRASE=@PASS_PHRASE@"
  setPassPhrase
}

# GitHubトークンを更新する
# .zshrc_original 内の GITHUB_TOKEN を置き換えて再設定
function updateGithubToken() {
  zshrcOriginalReplaceWordOfRegExp "GITHUB_TOKEN=.*$" "GITHUB_TOKEN=@GITHUB_TOKEN@"
  setGithubToken
}

# LDAPパスワードを更新する
# LDAP_STG_PASS と LDAP_PRD_PASS を置換して再設定
function updateLdapPass() {
  zshrcOriginalReplaceWordOfRegExp "LDAP_STG_PASS=.*$" "LDAP_STG_PASS=@LDAP_STG_PASS@"
  zshrcOriginalReplaceWordOfRegExp "LDAP_PRD_PASS=.*$" "LDAP_PRD_PASS=@LDAP_PRD_PASS@"
  setLdapPass
}

# LDAP_USERを置換して再設定
function updateLdapUser() {
  zshrcOriginalReplaceWordOfRegExp "LDAP_USER=.*$" "LDAP_USER=@LDAP_USER@"
  setLdapUser
}


# サブコマンド
# init -> 環境再構築
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
