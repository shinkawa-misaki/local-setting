namespacce UI
import util/class

class:UI.Cursor() {
  # http://askubuntu.com/questions/366103/saving-more-corsor-positions-with-tput-in-bash-terminal
	# http://unix.stackexchange.com/questions/88296/get-vertical-cursor-position

  # ターミナル内でのカーソルの 列番号 と 行番号 を格納するための隠し変数
	private integer x
	private integer y

  # カーソル位置をキャプチャする
  UI.Cursor.capture() {
    local x
    local y
    IFS=';' read -sdR -p $'\E[6n' y x

    this y = $(( ${y#*[} - 1 ))
    this x = $(( ${x} - 1 ))

    @return
  }

  # カーソル位置を復元する
  UI.Cursor.restore() {
    [integer] shift=1

    local -i totalHeight=$(tput lines)
    local -i y=$(this y)
    local -i x=$(this x)

    (( $y + 1 == $totalHeight )) && y+=-$shift

    tput cup $y $x

    @return
  }
}

: <<- 'COMENTOUT'
  # クラスのメタデータを構築
  #　this キーワードでアクセスできるオブジェクトの仕組みを有効化
  #　@return などの専用キーワードが正しく動作するように設定
  #　以降のスクリプト中で UI.Cursor がまるでオブジェクトのように振る舞うようになる
COMENTOUT

Type::Initialize UI.Cursor
