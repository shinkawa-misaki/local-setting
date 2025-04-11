namespace helpers
set -e

## IMPORT ##
# no dependencies
# ------------------------ #

## MAIN ##
# ------------------------ #
# スピナーを表示する関数
Spinner::Execute() {
  local pid="$1"
  local word="$2"
  local delay=0.1
  local spin='|/-\\'

  echo -e ""
  # スピナーを回しながらバックグラウンド処理を待つ
  while kill -0 "$pid" 2>/dev/null; do
    for i in {0..3}; do
      echo -ne "\r${word}... ${spin:$i:1}" 1>&2  # スピナーをstderrに出力
      sleep "$delay"
    done
  done

  # wait してプロセスの終了を確認
  wait "$pid" 2>/dev/null
}

# スピナーをバックグラウンドで実行する関数
Spinner::SetUp() {
  local pid=$1
  local word="${2:-"処理中"}"

  # スピナーをバックグラウンドで実行
  Spinner::Execute "$pid" "$word" &
}

# バックグラウンドプロセスが終了するまで監視する関数
Spinner::Down() {
  local pid=$1

  # 処理の完了後にスピナーの出力を消す(カーソルを1行上に戻す->その行を消去)
  wait "$pid"
  tput cr    # カーソルを行の先頭に移動
  tput cuu1  # カーソルを1行上に戻す
  tput el    # その行を消去
}

alias spinnerSetUp='Spinner::SetUp'
alias spinnerDown='Spinner::Down'
