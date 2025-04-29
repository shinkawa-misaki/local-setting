namespace helpers
set -e

## IMPORT ##
# ------------------------ #
import util_ext/log
import util_ext/zsh
import util_ext/gsed
import util_ext/providers
import helpers/patch

## MAIN ##
# ------------------------ #
# .zprofileを初期化して設定する
ZshCommon::SetZprofile() {
  outputStartLog "init .zprofile"
  cp -f "$base_zprofile_path" "$zprofile_path"
  outputResultLog $? "init .zprofile"
}

# zshと関連設定をインストール
ZshCommon::Install() {
  outputInfoLog "$zshrc_path & $zshrc_original_path setting start..."
  local answer
  inputMsg "oh-my-zshを適用しますか？（y/n）:"
  read -r answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    ZshCommon::InstallOhMyZsh
  else
    if [[ ! -f "$zshrc_path" ]]; then
      touch "$zshrc_path"
    fi
  fi
  ZshCommon::InitZshrcOriginal
  local bom_hex
  bom_hex=$(xxd -p -l 3 "$zshrc_path")

  # BOMが付いてい流場合の処理
  if [[ "$bom_hex" == "efbbbf" ]]; then
    # oh-my-zsh の基本設定
    gsed -i '1s/^\xEF\xBB\xBF//' "$zshrc_path"
    gsAddUniqueRowSudo "export ZSH=\"\$HOME/.oh-my-zsh\"" "$zshrc_path"
    gsAddUniqueRowSudo "ZSH_THEME=\"wedisagree\"" "$zshrc_path"
    gsAddUniqueRowSudo "plugins=(git)" "$zshrc_path"
    gsAddUniqueRowSudo "source \$ZSH/oh-my-zsh.sh" "$zshrc_path"
  fi
  outputInfoLog "$zshrc_path & $zshrc_original_path setting complete!"
}

# Homebrew経由でzshをインストール
ZshCommon::InstallByBrew() {
  local res
  res=$(sudo chmod 777 /etc/shells 2> /dev/null || echo 1)
  # 権限変更に成功した場合のみzshをインストール
  if [[ "$res" -eq 0 ]]; then
    outputStartLog "install zsh"
    brew install zsh
    outputResultLog $? "install zsh"

    # インストールしたzshを/etc/shellsに追加
    if [[ -f "$zsh_path" ]]; then
      local log_message="add $zsh_path to /etc/shells"
      gsAddUniqueRowSudo "${zsh_path//\//\\/}\n" "/etc/shells" "^" "$log_message"
    fi

    # デフォルトシェルを変更
    outputStartLog "chsh -s $zsh_path"
    chsh -s $zsh_path
    outputResultLog $? "chsh -s $zsh_path"

    sudo chmod 644 /etc/shells
  fi
}

# oh-my-zshをインストール
ZshCommon::InstallOhMyZsh() {
  local back_up_path="${zshrc_path}_${USER}_bk"
  # バックアップがない場合のみ現在の.zshrcをバックアップ
  if [[ -f $zshrc_path && ! -f $back_up_path ]]; then
    outputInfoLog "back up $zshrc_path to $back_up_path"
    cp "$zshrc_path" "$back_up_path"
    outputResultLog $? "back up $zshrc_path to $back_up_path"
  fi

  outputStartLog "install oh-my-zsh"
  echo "y" | curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
  outputResultLog $? "install oh-my-zsh"

  # テーマをwedisagreeに設定
  outputStartLog "$zshrc_path & $zshrc_original_path setting"
  gsed -i -e 's/ZSH_THEME="robbyrussell"/ZSH_THEME="wedisagree"/' "$zshrc_path"
  outputResultLog $? "$zshrc_path & $zshrc_original_path setting"

  # バックアップから差分を適用
  if [[ -f "$back_up_path" ]]; then
    patchExecute "$zshrc_path" "$back_up_path"
  fi
}

# オリジナルのzshrcを初期化する
ZshCommon::InitZshrcOriginal() {
  local init_status="y"

  outputStartLog "init $zshrc_original_path"
  # 初期化の確認をユーザーに促す
  if [[ -f "$zshrc_original_path" ]]; then
    ZshCommon::outputSetting
    inputMsg "$zshrc_original_path を初期化しますか？（y/n）:"
    read -r init_status
  fi

  # ユーザーが初期化を許可した場合またはファイルがない場合に初期化
  if [[ ! -f "$zshrc_original_path" || "$init_status" == "y" || "$init_status" == "Y" ]]; then
    outputStartLog "copy .zshrc_original"
    cp -f "$base_zshrc_original_path" "$zshrc_original_path"
    outputResultLog $? "copy .zshrc_original"
    ZshCommon::SetPassPhrase && \
    ZshCommon::SetGithubToken && \
    ZshCommon::SetLdapUser && \
    ZshCommon::SetLdapPass
  fi
  outputResultLog $? "init $zshrc_original_path"
}

ZshCommon::outputSetting() {
  local settings=(
    "PASS_PHRASE"
    "GITHUB_TOKEN"
    "LDAP_USER"
    "LDAP_STG_PASS"
    "LDAP_PRD_PASS"
  )

  local zshrc_original_setting
  for target in ${settings[*]}; do
    local str
    str=$(gsed -n "s/^.*${target}=//p" "$zshrc_original_path" | head -n 1)
    local mask="*"
    local masked
    masked="$(printf '%*s' $(( ${#str} - 5 )) '' | tr ' ' "$mask")${str: -5}"
    zshrc_original_setting+=$(printf "\\\n%s" "$target=$masked")
  done
  outputInfoLog "$zshrc_original_path setting${zshrc_original_setting}"
}

# zsh関連の設定をアンインストール
ZshCommon::UnInstall() {
  outputInfoLog "$zshrc_path & $zshrc_original_path unsetting start..."
  ZshCommon::UnInstallOhMyZsh
#  ZshCommon::UnInstallByBrew
  outputInfoLog "$zshrc_path & $zshrc_original_path unsetting complete!"
}

# Homebrew経由でインストールしたzshをアンインストール
ZshCommon::UnInstallByBrew() {
  # デフォルトシェルがzshの場合は変更
  if [[ "$SHELL" == "$zsh_path" ]]; then
    outputStartLog "chsh -s /bin/zsh"
    chsh -s /bin/zsh
    outputResultLog $? "chsh -s /bin/zsh"
  fi

  local is_exist
  is_exist=$(brew list | grep -E -c '^zsh$' || [[ $? == 1 ]])
  # zshがインストールされていればアンインストール
  if [[ "$is_exist" -ne 0 ]]; then
    outputStartLog "uninstall zsh"
    brew uninstall zsh
    outputResultLog $? "uninstall zsh"
  fi

  # .zshrcと.zshrc_originalを削除
  if [[ -f "$zshrc_path" ]]; then
    outputInfoLog "rm $zshrc_path"
    rm "$zshrc_path"
  fi
  if [[ -f "$zshrc_original_path" ]]; then
    outputInfoLog "rm $zshrc_original_path"
    rm "$zshrc_original_path"
  fi
}

# oh-my-zshをアンインストール
ZshCommon::UnInstallOhMyZsh() {
  local result
  if [[ -e ~/.oh-my-zsh ]]; then
    local back_up_path="${zshrc_path}_${USER}_bk"
    # バックアップがなければ作成
    if [[ ! -e $back_up_path ]]; then
      outputInfoLog "back up $zshrc_path to $back_up_path"
      cp "$zshrc_path" "$back_up_path"
      outputResultLog $? "back up $zshrc_path to $back_up_path"
    fi

    outputInfoLog "need uninstall oh-my-zsh"
    outputStartLog "uninstall oh-my-zsh"
    if [[ -f ~/.oh-my-zsh/tools/uninstall.sh ]]; then
      echo "y" | sh ~/.oh-my-zsh/tools/uninstall.sh
    fi
    result=$?

    if [[ -f ~/.oh-my-zsh ]]; then
      rm -rf ~/.oh-my-zsh ~/.zshrc.pre-oh-my-zsh*
    fi
    result+=$?

    outputResultLog "$result" "uninstall oh-my-zsh"
  fi
}

# パスフレーズを設定する
ZshCommon::SetPassPhrase() {
  inputMsg "PASS PHRASE:"
  read -r passPhrase
  if [[ "${#passPhrase}" -eq 0 ]]; then
    local passPhrase="\"\""
  fi
  zshrcOriginalReplaceWord "@PASS_PHRASE@" "\"$passPhrase\""
}

# GitHubトークンを設定する
ZshCommon::SetGithubToken() {
  inputMsg "GITHUB TOKEN:"
  read -r githubToken
  zshrcOriginalReplaceWord "@GITHUB_TOKEN@" "\"$githubToken\""
}

# LDAPユーザーを設定する
ZshCommon::SetLdapUser() {
  inputMsg "LDAP USER:"
  read -r ldapUser
  zshrcOriginalReplaceWord "@LDAP_USER@" "$ldapUser"
}

# LDAPパスワードを設定する
ZshCommon::SetLdapPass() {
  inputMsg "LDAP STG PASS:"
  read -r ldapStgPass
  zshrcOriginalReplaceWord "@LDAP_STG_PASS@" "\"$ldapStgPass\""

  inputMsg "LDAP PRD PASS:"
  read -r ldapPrdPass
  zshrcOriginalReplaceWord "@LDAP_PRD_PASS@" "\"$ldapPrdPass\""
}

alias setZprofile='ZshCommon::SetZprofile'
alias installZsh='ZshCommon::Install'
alias unInstallZsh='ZshCommon::UnInstall'
alias outputSettingZsh='ZshCommon::outputSetting'
alias setPassPhrase='ZshCommon::SetPassPhrase'
alias setGithubToken='ZshCommon::SetGithubToken'
alias setLdapUser='ZshCommon::SetLdapUser'
alias setLdapPass='ZshCommon::SetLdapPass'
