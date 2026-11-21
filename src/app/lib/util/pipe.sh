namespace util

# no dependencies

# 単純にパイプの中身を変数に読み込みたいが、前後の余計な空白は気にしない場合に使いたい
Pipe::Capture() {
  read -r -d '' $1 || true
}

# 入力の空白や末尾改行まで完全に保持したままキャプチャしたい時に使いたい
Pipe::CaptureFaithful() {
  IFS= read -r -d '' $1 || true
}
