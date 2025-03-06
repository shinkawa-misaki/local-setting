namespace util-ume/providers

## IMPORT ##
# ------------------------ #
# no dependencies
# ------------------------ #

## MAIN ##
# ------------------------ #
# Config ディレクトリのパスを取得する関数
Providers::ConfigDir() {
  echo "$LOCAL_SETTING/src/config"
}

# Resource ディレクトリのパスを取得する関数
Providers::ResourceDir() {
  echo "$LOCAL_SETTING/src/resource"
}

# モジュール設定ファイルのパスを取得する関数
Providers::GetConfigModules() {
  echo "$(Providers::ConfigDir)/modules.json"
}

# 指定されたファイル名の Resource ディレクトリが存在しない場合に作成し、そのパスを返す関数
Providers::GetResourceDir() {
  local target_file_name=$1
  local is_exist
  is_exist=$(ls -U1 "$(Providers::ResourceDir)" | grep -c "$target_file_name" 2> /dev/null || [[ $? == 1 ]])

  # ディレクトリが存在しない場合のみ作成する
  if [[ "$is_exist" -eq 0 ]]; then
    mkdir -p "$(Providers::ResourceDir)/$target_file_name"
  fi
  echo "$(Providers::ResourceDir)/$target_file_name"
}

# モジュール用の server ディレクトリパスを取得する関数
Providers::GetModuleServerResourceDir() {
  local module="$1"

  echo "$(Providers::GetResourceDir modules)/${module}/server"
}

Providers::CheckAppleSilicon() {
  local arch_type
  local is_rosetta
  arch_type=$(arch)
  is_rosetta=$(sysctl -in sysctl.proc_translated 2>/dev/null)

  if [[ "$arch_type" == "arm64" || "$is_rosetta" == "1" ]]; then
    echo 0
  else
    echo 1
  fi
}

Providers::GetCPUInfo() {
  local chip_info
  chip_info=$(system_profiler SPHardwareDataType | grep "Chip" | awk -F: '{print $2}' | xargs)

  if [[ "$chip_info" == Apple* ]]; then
    echo "$chip_info"  # 例: Apple M1, Apple M2
  else
    echo "Intel (or unknown)"
  fi
}

alias configDir='Providers::ConfigDir'
alias resourceDir='Providers::ResourceDir'
alias configModules='Providers::GetConfigModules'
alias getResourceDir='Providers::GetResourceDir'
alias resourceAlias='Providers::GetResourceDir alias'
alias resourceAws='Providers::GetResourceDir aws'
alias resourceDocker='Providers::GetResourceDir docker'
alias resourceModules='Providers::GetResourceDir modules'
alias resourceSSH='Providers::GetResourceDir ssh'
alias resourceTool='Providers::GetResourceDir tool'
alias resourceZsh='Providers::GetResourceDir zsh'
alias resourceModuleServer='Providers::GetModuleServerResourceDir'
alias checkAppleSilicon='Providers::CheckAppleSilicon'
alias getCPUInfo='Providers::GetCPUInfo'
