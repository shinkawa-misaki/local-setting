#!/usr/bin/env bash
set -e

# 他モジュールやサブコマンドを動的に呼び出す基点
declare current
current="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
declare script_dir="${current}/src/app/commands"

#==================================================
# zsh による再ログイン処理（zsh が存在する場合のみ）
# 目的：設定変更後に zsh へ再ログイン（zsh -l）し、即時反映
#流れ：command -v zsh → 存在確認 → zsh -l 実行→ zsh が存在しなければスキップ
#==================================================
function shellReLogin() {
  local zsh_path
  zsh_path=$(command -v zsh)

  local is_exist
  is_exist=$( (ls "$zsh_path" | wc -l | sed 's/ //g') 2> /dev/null || [[ $? == 1 ]])
  if [[ "$is_exist" -ne 0 ]]; then
    $zsh_path -l
  fi
}

#==================================================
# 汎用ログ出力処理（ログ種別・色・関数名・スクリプト・行番号付き）
# outputLog(type, color, message)：日時／種類／呼び出し元情報付きで出力。
# Start／Success／Error のログを統一フォーマットで出力。
#==================================================
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

# 処理開始ログ（INFO）
function outputStartLog() {
  local target="$1"
  outputLog "INFO" "34" "$target ${FUNCNAME[1]} Start."
}

# 処理成功ログ（INFO）
function outputSuccessLog() {
  local target="$1"
  outputLog "INFO" "34" "$target ${FUNCNAME[1]} Success."
}

# エラーメッセージを標準エラーに出力（ERROR）
function outputErrorLog() {
  outputLog "ERROR" "31" "Please Retry Command!!!" 1>&2
}

# 処理の成功・失敗に応じたログを出力し、初期化ポイントを進める
# 戻り値に応じて Success/Error を切り分け、INIT_LOCAL_POINT をインクリメント。
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

# 環境のローカル初期化処理（ステップ制御あり）
# 順次実行：zsh,alias,tool,Install,zsh,ssh:完了後は再ログイン
function initLocal() {
  # ステップ0: zsh 初期化
  if [[ "$INIT_LOCAL_POINT" -eq 0 ]]; then
    outputStartLog "zsh"
    ${script_dir}/zsh.sh init              # zsh 設定スクリプトを初期化モードで実行
    outputResultLog $? "zsh"              # 実行結果に応じてログ出力とカウント更新
  fi

  # ステップ1: alias 初期化
  if [[ "$INIT_LOCAL_POINT" -eq 1 ]]; then
    outputStartLog "alias"
    ${script_dir}/alias.sh init
    outputResultLog $? "alias"
  fi

  # ステップ2: tool のインストール処理
  if [[ "$INIT_LOCAL_POINT" -eq 2 ]]; then
    outputStartLog "tool"
    ${script_dir}/toolInstall.sh init
    outputResultLog $? "tool"
  fi

  # ステップ3: zsh original 設定ファイルを適用（ログ出力なし）
  if [[ "$INIT_LOCAL_POINT" -eq 3 ]]; then
    ${script_dir}/zsh.sh update original
  fi

  # ステップ3: ssh 初期設定（original 適用後に実行）
  if [[ "$INIT_LOCAL_POINT" -eq 3 ]]; then
    outputStartLog "ssh"
    ${script_dir}/ssh.sh init all
    outputResultLog $? "ssh"
  fi

  # ステップ4: 初期化完了後、zsh で再ログインして終了
  if [[ "$INIT_LOCAL_POINT" -eq 4 ]]; then
    export INIT_LOCAL_POINT=0
    shellReLogin
  fi
}

# モジュール初期化処理（ドメイン名を正規化して対応ファイルを実行）
# gsedで小文字化＋キャメル化＋ハイフン除去
function initModules() {
  local domain="${2}"
  local module
  module="$(echo "${domain}" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  shift;shift;

  # モジュールファイルが存在すれば、init モードで呼び出して zsh 再ログイン
  if [[ -e "${script_dir}/modules/${module}.sh" ]]; then
    ${script_dir}/modules/${module}.sh init "${@}"
    shellReLogin
  else
    echo "init setting is not found $domain"
  fi
}

# モジュール更新処理（ドメイン名の正規化 → ファイル存在チェック → 実行）
function updateModules() {
  local domain="${2}"
  local module
  module="$(echo "${domain}" | gsed -re's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  shift;shift;

  # 対象のモジュール更新処理が存在すれば実行、なければエラーメッセージ
  if [[ -e "${script_dir}/modules/${module}.sh" ]]; then
    ${script_dir}/modules/${module}.sh update "${@}"
  else
    echo "update setting is not found $domain"
  fi
}

# モジュール削除処理（updateModulesと構造は同一）
function deleteModules() {
  local domain="$2"
  local module
  module="$(echo "${domain}" | gsed -re 's/.*/\L\0/g; s/(-|_)([a-z0-9])/\U\0/g; s/(-|_)//g;')"
  shift;shift;

  if [[ -e "${script_dir}/modules/${module}.sh" ]]; then
    ${script_dir}/modules/${module}.sh delete "${@}"
  else
    echo "update setting is not found $domain"
  fi
}

# LOCAL_SETTING:このスクリプトの実行ルート設定
if [[ "$LOCAL_SETTING" == "" ]]; then
  export LOCAL_SETTING="${current}"
fi

# INIT_LOCAL_POINT:初期化ステップのカウンタを初期化
if [[ "$INIT_LOCAL_POINT" == "" || $DELETE_LOCAL_POINT -gt 4 ]]; then
  export INIT_LOCAL_POINT=0
fi

## ============================== ##
##           MAIN処理            ##
## ============================== ##

# "init" サブコマンド処理
# サブコマンド第二引数で細かく分岐するか、モジュール化
if [[ "$1" == "init" ]]; then
  case ${2} in
    "local" ) initLocal;;                                 # 全体初期化処理
    "zsh"   ) ${script_dir}/zsh.sh init && shellReLogin;;
    "alias" ) ${script_dir}/alias.sh init && shellReLogin;;
    "ssh"   ) ${script_dir}/ssh.sh init "${3}";;
    "tool"  ) ${script_dir}/toolInstall.sh init "${3}";;
           *) initModules ${@};;                          # 任意モジュールの初期化
  esac
fi

# "update" サブコマンド処理
# サブコマンド第二引数で細かく分岐するか、モジュール化
if [[ "$1" == "update" ]]; then
  case ${2} in
    "zsh"   ) ${script_dir}/zsh.sh update "${3}" && shellReLogin;;
    "alias" ) ${script_dir}/alias.sh update "${3}" "${4}" && shellReLogin;;
    "ssh"   ) ${script_dir}/ssh.sh update "${*:3}";;
    "tool"  ) ${script_dir}/toolInstall.sh update "${3}";;
           *) updateModules ${@};;                        # 任意モジュールの更新
  esac
fi

# "delete" サブコマンド処理
# サブコマンド第二引数で細かく分岐するか、モジュール化
if [[ "$1" == "delete" ]]; then
  case ${2} in
    "zsh"   ) ${script_dir}/zsh.sh delete "${3}" && shellReLogin;;
    "alias" ) ${script_dir}/alias.sh delete "${3}" && shellReLogin;;
    "tool"  ) ${script_dir}/toolUnInstall.sh delete "${3}";;
           *) deleteModules ${@};;                        # 任意モジュールの削除
  esac
fi

# "docker" サブコマンド処理
# 直接スクリプトを実行
if [[ "$1" == "docker" ]]; then
  shift;
  ${current}/src/app/commands/docker.sh $@
fi

# "upgrade" サブコマンド処理
# 直接スクリプトを実行
if [[ "$1" == "upgrade" ]]; then
  shift;
  ${script_dir}/upgrade.sh $@
fi
