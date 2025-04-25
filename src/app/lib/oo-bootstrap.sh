#!/usr/bin/env bash

set -euo pipefail

#=======================
# ブートストラップスクリプト
#=======================

# デバッグ用環境変数が設定されているか判定し、DEBUGエイリアスを定義
if [[ -n "${__INTERNAL_LOGGING__:-}" ]]
then
  alias DEBUG=":; "
else
  alias DEBUG=":; #"  #コメント化
fi


#===========================================================
#System::SourceHTTP() {
#  local URL="$1" RETRIES=3
#  shift
#
#  if command -v curl >/dev/null; then
#    builtin source <(
#      curl --fail -sL --retry "$RETRIES" "$URL" \
#        || { [[ "$URL" != *.sh && "$URL" != *.bash" ]] && curl --fail -sL --retry "$RETRIES" "${URL}.sh"; } \
#        || echo "e='Cannot import $URL' throw"
#    ) "$@"
#  else
#    builtin source <(
#      wget -qO- -t "$RETRIES" "$URL" \
#        || { [[ "$URL" != *.sh && "$URL" != *.bash" ]] && wget -qO- -t "$RETRIES" "${URL}.sh"; } \
#        || echo "e='Cannot import $URL' throw"
#    ) "$@"
#  fi
#
#  __oo__importedFiles+=( "$URL" )
#}
#という書き方はどうかな？短くなってみやすくなると思うんだけど。。
#===========================================================
# URLから直接Bashスクリプトを取得してsourceする関数
System::SourceHTTP() {
  local URL="$1"
  local -i RETRIES=3
  shift

  if hash curl 2> /dev/null
  then
     # curlがあればcurlで取得
    builtin source < $(curl --fail -sL --retry $RETRIES "${URL}" || { [[ "$URL" != *'.sh' && "$URL" != *'.bash' ]] && curl --fail -sL --retry $RETRIES "${URL}.sh"; } || echo "e='Cannot import $URL' throw") "$@"
  else
     # curlがなければwgetで取得
    builtin source < $(wget -t $RETRIES -O - -o /dev/null "${URL}" || { [[ "$URL" != *'.sh' && "$URL" != *'.bash' ]] && wget -t $RETRIES -O - -o /dev/null "${URL}.sh"; } || echo "e='Cannot import $URL' throw") "$@"
  fi
   #読み込み済みURLをリストに追加
  __oo__importedFiles+=( "$URL" )
}

# ファイルパスからローカルファイルをsourceする関数
System::SourceFile() {
  local libPath="$1"
  shift

   # 存在しなければ1を返して終了
  [[ ! -f "$libPath" ]] && return 1

  # 絶対パスに変換
  libPath="$(File::GetAbsolutePath "$libPath")"

#===========================================================
#if [[ "${__oo__allowFileReloading-}" != true ]] \
#  && [[ -n "${__oo__importedFiles[*]}" ]] \
#  && Array::Contains "$libPath" "${__oo__importedFiles[@]}"; then
#  return 0
#fi
#
#ここもこう書くと読みやすくなると思いました。。。Σ(゜Д゜ノ)ノ
#===========================================================
    # すでにインポート済みなら再度読み込まないよ！
    if [[ "${__oo__allowFileReloading-}" != true ]] && [[ ! -z "${__oo__importedFiles[*]}" ]] && Array::Contains "$libPath" "${__oo__importedFiles[@]}"
    then
      return 0
    fi

    # インポート済みリストを更新
    importedFile+=( "$libPath" )
    __oo__importedFiles=( $( {
              printf "%s\n" "${__oo__importedFiles[@]}"
              printf "%s\n" "${importedFile[@]}"
            } | sort -u ) )
      # 親ディレクトリを設定してWrapSource経由で読み込む
    __oo__importParent=$(dirname "$libPath") System::WrapSource "$libPath" "$@"
  }


# ディレクトリまたはファイルパスからまとめてsourceする関数
System::SourcePath() {
  local libPath="$1"
  shift
  # echo trying $libPath
  if [[ -d "$libPath" ]]
  then
    local file
    # ディレクトリ内の .sh をすべて読み込む
    for file in "$libPath"/*.sh
    do
      System::SourceFile "$file" "$@"
    done
  else
     # ファイル名付き or .sh付きを試す
    System::SourceFile "$libPath" "$@" || System::SourceFile "${libPath}.sh" "$@"
  fi
}

# ファイルディスクリプタパス取得用の設定
declare -g __oo__fdPath=$(dirname <(echo))
declare -gi __oo__fdLength=$(( ${#__oo__fdPath} + 1 ))



#====================
#めっちゃ整理したい。。
#====================
# 単一インポートのエントリーポイント関数
System::ImportOne() {
  local libPath="$1"
  local __oo__importParent="${__oo__importParent-}"
  local requestedPath="$libPath"
  shift

# GitHub Raw URL変換
  if [[ "$requestedPath" == 'github:'* ]]
  then
    requestedPath="https://raw.githubusercontent.com/${requestedPath:7}"
  elif [[ "$requestedPath" == './'* ]]
  then
    requestedPath="${requestedPath:2}"
  elif [[ "$requestedPath" == "$__oo__fdPath"* ]]
  then
    requestedPath="${requestedPath:$__oo__fdLength}"
  fi
# 親ディレクトリ相対パス付与（HTTP以外）
  if [[ "$requestedPath" != 'http://'* && "$requestedPath" != 'https://'* ]]
  then
    requestedPath="${__oo__importParent}/${requestedPath}"
  fi

# HTTP(S)ならSourceHTTPを呼び出し
  if [[ "$requestedPath" == 'http://'* || "$requestedPath" == 'https://'* ]]
  then
    __oo__importParent=$(dirname "$requestedPath") System::SourceHTTP "$requestedPath"
    return
  fi

# ローカルパスを順番に試行
  {
    local localPath="$( cd "${BASH_SOURCE[1]%/*}" && pwd )"
    localPath="${localPath}/${libPath}"
    System::SourcePath "${localPath}" "$@"
  } || \
  System::SourcePath "${requestedPath}" "$@" || \
  System::SourcePath "${libPath}" "$@" || \
  System::SourcePath "${__oo__libPath}/${libPath}" "$@" || \
  System::SourcePath "${__oo__path}/${libPath}" "$@" || e="Cannot import $libPath" throw
}

# 複数インポートをまとめて呼び出す関数
System::Import() {
  local libPath
  for libPath in "$@"
  do
    System::ImportOne "$libPath"
  done
}

# ファイル名から絶対パスを取得するヘルパー関数
File::GetAbsolutePath() {
  local file="$1"
  if [[ "$file" == "/"* ]]
  then
    echo "$file"
  else
    echo "$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
  fi
}

# スクリプトをそのままsourceするラッパー
System::WrapSource() {
  local libPath="$1"
  shift

  builtin source "$libPath" "$@" || throw "Unable to load $libPath"
}

# システム起動時に必要な初期化処理を行う関数
System::Bootstrap() {
   # Array/Containsライブラリがあるかチェック
  if ! System::Import Array/Contains
  then
    cat <<< "FATAL ERROR: Unable to bootstrap (missing lib directory?)" 1>&2
    exit 1
  fi
}


# デバッグプロンプトの設定
# PS4 にトレース用フォーマットを設定する
export PS4='+(${BASH_SOURCE##*/}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

set -o pipefail

# alias を関数内で使えるように設定
shopt -s expand_aliases

# グローバル変数にパス情報を設定する
declare -g __oo__libPath="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
declare -g __oo__path="${__oo__libPath}/.."
declare -ag __oo__importedFiles

# namespace, throw が未ロード時のスタブ定義
namespace() { :; }
throw() { eval 'cat <<< "Exception: $e ($*)" 1>&2; read -s;'; }

# 最後にブートストラップ処理を実行
System::Bootstrap

alias import="__oo__allowFileReloading=false System::Import"
alias source="__oo__allowFileReloading=true System::ImportOne"
alias .="__oo__allowFileReloading=true System::ImportOne"

# ブート済みフラグを設定
declare -g __oo__bootstrapped=true
