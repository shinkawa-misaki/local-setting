# 問題点・改善提案

> 各項目の「対応状況」は 2026/11/17 時点のもの。行番号は指摘した当時のもので、修正後はずれている場合がある。

---

## 重大度: 高（実行時エラーの可能性）

### 1. 未定義変数 `DELETE_LOCAL_POINT` の参照

**ファイル**: [localSetting.sh:147](localSetting.sh#L147)

```bash
if [[ "$INIT_LOCAL_POINT" == "" || $DELETE_LOCAL_POINT -gt 4 ]]; then
```

**問題点**:
- `DELETE_LOCAL_POINT` が定義されていない状態で参照されてんね
- `set -u` オプションで、未定義変数参照でスクリプトが停止する。

**修正案**:
```bash
if [[ "$INIT_LOCAL_POINT" == "" || ${DELETE_LOCAL_POINT:-0} -gt 4 ]]; then
```

**対応状況**: ✅ 対応済み
- `INIT_LOCAL_POINT` もリポジトリのどこでも設定されていなかったため、環境変数を渡さずに実行するとどのコマンドも147行目で止まっていた
- `"${INIT_LOCAL_POINT:-}"` と `"${DELETE_LOCAL_POINT:-0}"` に修正（`LOCAL_SETTING` も同様）

---

### 2. 変数代入の構文エラー

**ファイル**: [src/app/commands/zsh.sh:34](src/app/commands/zsh.sh#L34)

```bash
string -g zsh_path=in_dir="$(brew --prefix)/bin/zsh"
```

**問題点**:
- `zsh_path=in_dir=` という構文は意図した動作をしないかも
- `zsh_path` に `in_dir=...` という文字列が代入されるから

**修正案**:
```bash
string -g zsh_path="$(brew --prefix)/bin/zsh"
```

**対応状況**: ✅ 対応済み（修正案のとおり）

---

### 3. 未定義変数 `remove_alias_path` の使用

**ファイル**: [src/app/commands/alias.sh:83-94](src/app/commands/alias.sh#L83-L94)

```bash
function remove() {
  outputInfoLog "$remove_alias_path unsetting start..."
  if [[ -e "$remove_alias_path" ]]; then
    ...
  fi
}
```

**問題点**:
- `remove_alias_path` が定義されていな
- `alias_path` を使用するか、引数で受け取るべきかも？

**修正案**:
```bash
function remove() {
  local remove_alias_path="${1:-$alias_path}"
  outputInfoLog "$remove_alias_path unsetting start..."
  ...
}
```

**対応状況**: ✅ 対応済み（修正案のとおり。あわせて `rm` の引数を引用符で囲んだ）

---

### 4. 未定義変数 `etc_dir` の使用

**ファイル**: [src/app/commands/upgrade.sh:235-236](src/app/commands/upgrade.sh#L235-L236)

```bash
function upgradeTestSetting() {
  ...
  if [[ -d $etc_dir/anyenv.d ]]; then
    sudo rm -rf $etc_dir/anyenv.d
  fi
}
```

**問題点**:
- `etc_dir` が `upgradeTestSetting` 関数内で定義されていない
- `deleteTool` 関数内では定義されてるけど、スコープが異なる

**修正案**:
```bash
function upgradeTestSetting() {
  local etc_dir
  etc_dir="$(brew --prefix)/etc"
  ...
}
```

**対応状況**: ✅ 対応済み（修正案のとおり）
- 修正前は `etc_dir` が空のため、`sudo rm -rf $etc_dir/anyenv.d` が `/anyenv.d` を対象にしていた。パスも引用符で囲んだ

---

### 5. `$var:ssh_key_dir` の構文エラー

**ファイル**: [src/app/commands/ssh.sh:56](src/app/commands/ssh.sh#L56)

```bash
find $($var:ssh_key_dir) -type f -not -name "*.pub" -print 2> /dev/null | \
```

**問題点**:
- `$($var:ssh_key_dir)` はコマンド置換として解釈される
- 正しくは `$ssh_key_dir` または OOPフレームワークの構文に従う

**修正案**:
```bash
find "$ssh_key_dir" -type f -not -name "*.pub" -print 2> /dev/null | \
```

**対応状況**: ❎ 問題なし（指摘の誤り）
- `$var:変数名` は bash-oo-framework の正式な構文（`util/namedParameters.sh` で `var` が定義されている）
- `string` などで宣言した変数の値を取り出す書き方なので、`$($var:ssh_key_dir)` で `ssh_key_dir` の値が得られる
- その後 `cleanUpSSHAdd` を書き直した（`ssh-add -D` をやめた）ので、今のコードではこの箇所は `"$ssh_key_dir"` になっている
- リポジトリ内でも `$var:` は50か所ほど使われている

---

## 重大度: 中（潜在的な問題）

### 6. gsedコマンドのスペースが不足してる

**ファイル**: [localSetting.sh:119](localSetting.sh#L119)

```bash
module="$(echo "${domain}" | gsed -re's/.*/\L\0/g; ...')"
```

**問題点**:
- `-re's/...` の間にスペースがない（他の箇所では `-re 's/...` と記述）
- 動作する場合もあるが、一貫性がないかな

**修正案**:
```bash
module="$(echo "${domain}" | gsed -re 's/.*/\L\0/g; ...')"
```

**対応状況**: ✅ 対応済み（修正案のとおり）

---

### 7. ファイル名の大文字小文字の不一致があった

**ファイル**: [localSetting.sh:176](localSetting.sh#L176)

```bash
"tool"  ) ${script_dir}/toolUnInstall.sh delete "${3}";;
```

**問題点**:
- 実際のファイル名は `toolUninstall.sh`（小文字の `i`）で、参照している `toolUnInstall.sh`（大文字の `I`）と一致していない
- macOS のファイルシステムは大文字小文字を区別しないため Mac では動くが、Linux（Docker のテスト環境）では見つからずに失敗する

**修正案**:
```bash
"tool"  ) ${script_dir}/toolUninstall.sh delete "${3}";;
```

**対応状況**: ✅ 対応済み（参照側をファイル名に合わせた）

---

### 8. 引数なしで実行時のエラー

**ファイル**: [localSetting.sh:151-189](localSetting.sh#L151-L189)

```bash
if [[ "$1" == "init" ]]; then
  case ${2} in
    ...
  esac
fi
```

**問題点**:
- 引数なしで実行すると `$1` や `$2` が未定義
- `set -u` で実行時エラーになる

**修正案**:
```bash
if [[ "${1:-}" == "init" ]]; then
  case ${2:-} in
    ...
  esac
fi
```

またはヘルプ表示を追加:
```bash
if [[ $# -eq 0 ]]; then
  echo "Usage: ./localSetting.sh <command> <subcommand> [options]"
  exit 1
fi
```

**対応状況**: ✅ 対応済み（ヘルプ表示は未対応）
- 引数を `declare cmd="${1:-}" target="${2:-}" arg3="${3:-}" arg4="${4:-}"` で受け取るように修正
- あわせて、`zsh.sh init && shellReLogin` のように `&&` でつないでいたため、サブコマンドが失敗しても終了コードが 0 になっていた問題も修正

---

## 重大度: 低（コード品質の改善）

### 9. 重複コードの存在

**ファイル**: 複数

`shellReLogin` 関数が以下の複数ファイルで重複定義されている：
- `localSetting.sh:9-18`
- `src/app/commands/upgrade.sh:43-52`

**修正案**:
共通ライブラリに移動して `import` で使用

---

### 10. コメント内のリファクタリング提案が未実施

**ファイル**: [src/app/commands/upgrade.sh](src/app/commands/upgrade.sh)

コード内に複数のリファクタリング提案がコメントとして残されている：

```bash
#=============================================================
#function shellRelohin() {
# if command -v zsh >/dev/null 2>&1; then
#   zsh -l
# fi
#}
# これでまとまるかな？？ls,wc,sedなしで書けそうな気がしています。。。
#=============================================================
```
- これは余計だから消す🔥

---

### 11. ハードコードされたパス

**ファイル**: [src/app/commands/toolInstall.sh:84-100](src/app/commands/toolInstall.sh#L84-L100)

```bash
zshrcAddWord "PATH=/usr/local/opt/coreutils/libexec/gnubin:\$PATH" "^"
```

**問題点**:
- `/usr/local/opt/` はIntel Macのパス
- Apple Silicon（M1以降）では `/opt/homebrew/opt/` になる

**修正案**:
```bash
local brew_prefix
brew_prefix="$(brew --prefix)"
zshrcAddWord "PATH=${brew_prefix}/opt/coreutils/libexec/gnubin:\$PATH" "^"
```

**対応状況**: ✅ 対応済み（修正案のとおり）
- findutils と gzip はパス自体も間違っていた（`/usr/local/opt/coreutils/findutils/gnubin` など）
  - findutils は `${brew_prefix}/opt/findutils/libexec/gnubin` に修正
  - gzip は `$(brew --prefix)/bin` に直接入り gnubin がないため、PATH の追記をやめた

---

### 12. エラーハンドリングの不足

**ファイル**: 複数

多くの関数で `brew` コマンドの失敗時のエラーハンドリングがない。

**修正案**:
```bash
if ! brew install tig; then
  echo "Error: Failed to install tig" >&2
  return 1
fi
```

---

### 13. ドキュメント・ヘルプの不足

- `--help` オプションを実装してもいいかも

