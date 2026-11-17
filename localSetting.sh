#!/usr/bin/env bash
set -euo pipefail

declare current
current="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
declare script_dir="${current}/src/app/commands"


function shellReLogin() {
  local zsh_path
  zsh_path=$(command -v zsh)

  local is_exist
  is_exist=$( (ls "$zsh_path" | wc -l | sed 's/ //g') 2> /dev/null || [[ $? == 1 ]])
  if [[ "$is_exist" -ne 0 ]]; then
    $zsh_path -l
  fi
}


function outputLog() {
  local type="$1"
  local color="$2"
  local message="$3"
  local bash_path="${BASH_SOURCE[${#BASH_SOURCE[@]}-2]}"
  local bash_dir="${bash_path%/*}"
  local script="${bash_dir##*/}/${bash_path##*/}:${FUNCNAME[2]}"
  local lineNo=${BASH_LINENO[1]}

  echo -e "\e[${color}m[$(date +"%Y/%m/%d %H:%M:%S")] [${type}]\e[m \e[34m[${script}:${lineNo}]\e[m ${message}"
}


function outputStartLog() {
  local target="$1"
  outputLog "INFO" "34" "$target ${FUNCNAME[1]} Start."
}


function outputSuccessLog() {
  local target="$1"
  outputLog "INFO" "34" "$target ${FUNCNAME[1]} Success."
}


function outputErrorLog() {
  outputLog "ERROR" "31" "Please Retry Command!!!" 1>&2
}


function outputResultLog() {
  local res="$1"
  local log_massage="$2"

  if [[ $res -eq 0 ]]; then
    outputSuccessLog "$log_massage"
    export INIT_LOCAL_POINT=$(( INIT_LOCAL_POINT + 1))
  else
    outputErrorLog 1>&2
  fi
}


function initLocal() {
  if [[ "$INIT_LOCAL_POINT" -eq 0 ]]; then
    outputStartLog "zsh"
    ${script_dir}/zsh.sh init          
    outputResultLog $? "zsh"         
  fi

  if [[ "$INIT_LOCAL_POINT" -eq 1 ]]; then
    outputStartLog "alias"
    ${script_dir}/alias.sh init
    outputResultLog $? "alias"
  fi

  if [[ "$INIT_LOCAL_POINT" -eq 2 ]]; then
    outputStartLog "tool"
    ${script_dir}/toolInstall.sh init
    outputResultLog $? "tool"
  fi

  if [[ "$INIT_LOCAL_POINT" -eq 3 ]]; then
    ${script_dir}/zsh.sh update original
  fi

  if [[ "$INIT_LOCAL_POINT" -eq 3 ]]; then
    outputStartLog "ssh"
    ${script_dir}/ssh.sh init all
    outputResultLog $? "ssh"
  fi

  if [[ "$INIT_LOCAL_POINT" -eq 4 ]]; then
    export INIT_LOCAL_POINT=0
    shellReLogin
  fi
}


function initModules() {
  local domain="${2:-}"
  local module
  module="$(echo "${domain}" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  set -- "${@:3}"  # 先頭2つ（サブコマンドとドメイン）を外す。引数が足りなくても止まらない

  
  if [[ -e "${script_dir}/modules/${module}.sh" ]]; then
    ${script_dir}/modules/${module}.sh init "${@}"
    shellReLogin
  else
    echo "init setting is not found $domain"
  fi
}


function updateModules() {
  local domain="${2:-}"
  local module
  module="$(echo "${domain}" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  set -- "${@:3}"
  
  if [[ -e "${script_dir}/modules/${module}.sh" ]]; then
    ${script_dir}/modules/${module}.sh update "${@}"
  else
    echo "update setting is not found $domain"
  fi
}


function deleteModules() {
  local domain="${2:-}"
  local module
  module="$(echo "${domain}" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  set -- "${@:3}"

  if [[ -e "${script_dir}/modules/${module}.sh" ]]; then
    ${script_dir}/modules/${module}.sh delete "${@}"
  else
    echo "update setting is not found $domain"
  fi
}

if [[ "${LOCAL_SETTING:-}" == "" ]]; then
  export LOCAL_SETTING="${current}"
fi

if [[ "${INIT_LOCAL_POINT:-}" == "" || "${DELETE_LOCAL_POINT:-0}" -gt 4 ]]; then
  export INIT_LOCAL_POINT=0
fi

# 引数が足りなくても set -u で止まらないよう、未指定の引数は空文字として扱う
declare cmd="${1:-}" target="${2:-}" arg3="${3:-}" arg4="${4:-}"

# gsed（GNU sed）はほぼすべてのサブコマンドで使う。
# tool の初期化より前の zsh の初期化でも使うため、ここで先に入れておく
if [[ -n "$cmd" ]] && ! command -v gsed > /dev/null 2>&1; then
  if command -v brew > /dev/null 2>&1; then
    echo "gsed が見つからないため、gnu-sed をインストールします"
    brew install gnu-sed
  else
    echo "gsed（gnu-sed）が必要ですが、Homebrew が見つかりません。先に Homebrew をインストールしてください: https://brew.sh" 1>&2
    exit 1
  fi
fi

if [[ "$cmd" == "init" ]]; then
  case "$target" in
    "local" ) initLocal;;
    "zsh"   ) ${script_dir}/zsh.sh init; shellReLogin;;
    "alias" ) ${script_dir}/alias.sh init; shellReLogin;;
    "ssh"   ) ${script_dir}/ssh.sh init "$arg3";;
    "tool"  ) ${script_dir}/toolInstall.sh init "$arg3";;
           *) initModules "$@";;
  esac
fi

if [[ "$cmd" == "update" ]]; then
  case "$target" in
    "zsh"   ) ${script_dir}/zsh.sh update "$arg3"; shellReLogin;;
    "alias" ) ${script_dir}/alias.sh update "$arg3" "$arg4"; shellReLogin;;
    "ssh"   ) ${script_dir}/ssh.sh update "${*:3}";;
    "tool"  ) ${script_dir}/toolInstall.sh update "$arg3";;
           *) updateModules "$@";;
  esac
fi

if [[ "$cmd" == "delete" ]]; then
  case "$target" in
    "zsh"   ) ${script_dir}/zsh.sh delete "$arg3"; shellReLogin;;
    "alias" ) ${script_dir}/alias.sh delete "$arg3"; shellReLogin;;
    "tool"  ) ${script_dir}/toolUninstall.sh delete "$arg3";;
           *) deleteModules "$@";;
  esac
fi

if [[ "$cmd" == "docker" ]]; then
  shift;
  ${current}/src/app/commands/docker.sh "$@"
fi

if [[ "$cmd" == "upgrade" ]]; then
  shift;
  ${script_dir}/upgrade.sh "$@"
fi
