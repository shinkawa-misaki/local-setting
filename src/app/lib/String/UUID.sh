# 自家製UUID発生器
String::GenerateUUID() {
  ## https://gist.github.com/markusfisch/6110640

  # N ：ループ用のカウンター
  # B ：ランダムバイトを一時的に保存するための変数
  # C ：UUIDで使われる「variant」用の文字セット
  local N B C='89ab'

  # 16バイト分繰り返す
  for (( N=0; N < 16; ++N ))
  do
    # 1バイト分のランダム値を生成
    B=$(( $RANDOM%256 ))

    case $N in
      6) # バージョンフィールド
        printf '4%x' $(( B%16 ))
      ;;
      8) # バリアントフィールド
        printf '%c%x' ${C:$RANDOM%${#C}:1} $(( B%16 ))
      ;;
      3 | 5 | 7 | 9) # UUIDの4バイトごとでハイフンを挿入
        printf '%02x-' $B
      ;;
      *) # 普通に2桁の16進数を出力
        printf '%02x' $B
      ;;
    esac
  done
}
