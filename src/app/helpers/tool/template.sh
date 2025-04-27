namespace helpers/tool

## IMPORT ##
# ------------------------ #
import util-ext/zsh
import helpers/tool/common

## DECLARATION ##
# ------------------------ #
string -g zshrc_path="$HOME/.zshrc"

## MAIN ##
# ------------------------ #
ToolTemplate::Install() {
  ToolTemplate::InstallPHP
  ToolTemplate::InstallRuby
  ToolTemplate:InstallIsolatedTools
}

ToolTemplate::UnInstall() {
  ToolTemplate::UnInstallIsolatedTools
  ToolTemplate::UnInstallRuby
  ToolTemplate::UnInstallPHP
}

ToolTemplate::InstallPHP() {
  local bin_dir
  bin_dir="$(brew --prefix)/bin"

  # php@8.1をインストール
  local installCommand="brew install shivammathur/php/php@8.1"
  toolInstall "brew" "php@8.1" "$installCommand"

  # php-cs-fixerをインストール
  if [[ ! -e $bin_dir/php-cs-fixer ]]; then
    curl -L https://cs.symfony.com/download/php-cs-fixer-v3.phar -o $bin_dir/php-cs-fixer
    chmod a+x $bin_dir/php-cs-fixer
  fi
}

ToolTemplate::InstallRuby() {
  # ruby-gemsetをインストール
  local installCommand="brew install rbenv-gemset"
  toolInstall "brew" "rbenv-gemset" "$installCommand"

  # ruby-buildをインストール
  local installCommand="brew install --ignore-dependencies ruby-build"
  toolInstall "brew" "ruby-build" "$installCommand"

  # rbenvをインストール
  local installCommand="anyenv install -f rbenv"
  toolInstall "anyenv" "rbenv" "$installCommand"

  # rbenvの一時的な有効化
  export PATH="$HOME/.anyenv/envs/rbenv/bin:$PATH"
  export RBENV_ROOT="$HOME/.anyenv/envs/rbenv"
  eval "$(rbenv init -)"
  export PATH="$RBENV_ROOT/shims:$PATH"
  rbenv rehash

  # rbenvを利用してrubyの2.7.8をインストール
  local installCommand="rbenv install -v 2.7.8"
  toolInstall "versions" "ruby" "$installCommand" "rbenv" "2.7.8"
}

ToolTemplate:InstallIsolatedTools() {
  # OpenSSLをインストール
  local installCommand="brew install --ignore-dependencies openssl@3"
  toolInstall "brew" "openssl@3" "$installCommand"

  # lolcatをインストール
  local installCommand="brew install lolcat"
  toolInstall "brew" "lolcat" "$installCommand"
}

ToolTemplate::UnInstallIsolatedTools() {
  # OpenSSLをアンインストール
  local unInstallCommand="brew uninstall --ignore-dependencies openssl@3"
  toolUnInstall "brew" "openssl@3" "$unInstallCommand"
}

ToolTemplate::UnInstallRuby() {
  # rubyの2.7.8をアンインストール
  local unInstallCommand="rbenv uninstall 2.7.8"
  toolUnInstall "versions" "ruby" "$unInstallCommand" "rbenv" "2.7.8"

  # ruby-buildをアンインストール
  local unInstallCommand="brew uninstall --ignore-dependencies ruby-build "
  toolUnInstall "brew" "ruby-build" "$unInstallCommand"

  # ruby-gemsetをアンインストール
  local unInstallCommand="brew uninstall rbenv-gemset"
  toolUnInstall "brew" "rbenv-gemset" "$unInstallCommand"
}

ToolTemplate::UnInstallPHP() {
  # php@8.1をアンインストール
  local uninstallCommand="brew uninstall php@8.1"
  toolUnInstall "brew" "php@8.1" "$uninstallCommand" "8.1"
  if [[ -e /usr/local/etc/php/8.1 ]]; then
    rm -rf /usr/local/etc/php/8.1
  fi
}

alias toolTemplateInstall='ToolTemplate::Install'
alias toolTemplateUnInstall='ToolTemplate::UnInstall'
