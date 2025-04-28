namespace util

# ネスト深度カウンタ／シェルオプション保存用
declare -ig __oo__insideTryCatch=0

# 現在のシェルオプション（set -e/-i など）を文字列として保存
declare -g __oo__presetShellOpts="$-"

# in case try-catch is nested, we set +e before so the parent handler doesn't catch us instead
# alias try='[[ $__oo__insideTryCatch -eq 0 ]] || __oo__presetShellOpts="$(echo $- | sed 's/[is]//g')"; __oo__insideTryCatch+=1; set +e; ( set -e; true; '
alias try='
  # 1) ネスト中なら上位の -e/-i オプションをいったん解除
  [[ $__oo__insideTryCatch -eq 0 ]] || \
    __oo__presetShellOpts="$(echo $- | sed "s/[is]//g")";
  # 2) ネスト深度をインクリメント
  __oo__insideTryCatch+=1;
  # 3) エラー無視モードにしてサブシェルを開始
  set +e;  ( set -e; true;
'

# alias catch='); declare __oo__tryResult=$?; __oo__insideTryCatch+=-1; [[ $__oo__insideTryCatch -lt 1 ]] || set -${__oo__presetShellOpts:-e} && Exception::Extract $__oo__tryResult || '
alias catch='
  )
  declare __oo__tryResult=$?      # try 内の最終コマンドの終了コードを保存
  __oo__insideTryCatch+=-1;       # ネスト深度をデクリメント
  # ネストがまだ残っていれば、元のシェルオプションを復元
  [[ $__oo__insideTryCatch -lt 1 ]] || set -${__oo__presetShellOpts:-e} &&
    # 例外情報を取り出し、戻り値に応じて catch 処理へ
    Exception::Extract $__oo__tryResult ||
'

# mktemp で一意のファイル名を生成し、グローバル変数に格納
Exception::SetupTemp() {
  declare -g __oo__storedExceptionLineFile="$(mktemp -t stored_exception_line.$$.XXXXXXXXXX)"
  declare -g __oo__storedExceptionSourceFile="$(mktemp -t stored_exception_source.$$.XXXXXXXXXX)"
  declare -g __oo__storedExceptionBacktraceFile="$(mktemp -t stored_exception_backtrace.$$.XXXXXXXXXX)"
  declare -g __oo__storedExceptionFile="$(mktemp -t stored_exception.$$.XXXXXXXXXX)"
}

Exception::CleanUp() {
  local exitVal=$?  # trap された時の終了コードを保持
  # 一時ファイルを削除してから、元の終了コードで exit
  rm -f $__oo__storedExceptionLineFile \
        $__oo__storedExceptionSourceFile \
        $__oo__storedExceptionBacktraceFile \
        $__oo__storedExceptionFile || exit 1
  exit $exitVal
}

# 一時ファイルを空にする
Exception::ResetStore() {
  > $__oo__storedExceptionLineFile
  > $__oo__storedExceptionFile
  > $__oo__storedExceptionSourceFile
  > $__oo__storedExceptionBacktraceFile
}

# もし例外ファイルが空でなければ、順番に内容を出力
Exception::GetLastException() {
  if [[ -s $__oo__storedExceptionFile ]]
  then
    cat $__oo__storedExceptionLineFile
    cat $__oo__storedExceptionFile
    cat $__oo__storedExceptionSourceFile
    cat $__oo__storedExceptionBacktraceFile

    Exception::ResetStore
  else
    # 例外がまだ保存されていなければ、現在の呼び出し箇所を返す
    echo -e "${BASH_LINENO[1]}\n \n${BASH_SOURCE[2]#./}"
  fi
}

Exception::Extract() {
  local retVal=$1
  unset __oo__tryResult

  if [[ $retVal -gt 0 ]]
  then
    local IFS=$'\n'
    __EXCEPTION__=( $(Exception::GetLastException) )

    local -i counter=0
    local -i backtraceNo=0

    while [[ $counter -lt ${#__EXCEPTION__[@]} ]]
    do
      __BACKTRACE_LINE__[$backtraceNo]="${__EXCEPTION__[$counter]}"
      counter+=1
      __BACKTRACE_COMMAND__[$backtraceNo]="${__EXCEPTION__[$counter]}"
      counter+=1
      __BACKTRACE_SOURCE__[$backtraceNo]="${__EXCEPTION__[$counter]}"
      counter+=1
      backtraceNo+=1
    done

    return 1 # so that we may continue with a "catch"
  fi
  return 0
}

Exception::SetupTemp

# スクリプト終了／割り込み時にクリーンアップを自動実行
trap Exception::CleanUp EXIT INT TERM
