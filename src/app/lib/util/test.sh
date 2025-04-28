namespace util
import util/class util/tryCatch UI/Cursor

class:Test() {
  private UI.Cursor onStartCursor
  private string groupName
  public string errors
  # public boolean errors = false

  # テスト開始の共通ログ出力を行い、カーソル位置を保存する
  Test.Start() {
    [string] verb
    [string] description

    this onStartCursor capture

    # 色やシンボルをまとめる
    local arrow="$(UI.Color.Yellow)$(UI.Powerline.PointingArrow)"
    local label="$(UI.Color.Yellow)[$(UI.Color.LightGray)$(UI.Color.Bold)TEST$(UI.Color.NoBold)$(UI.Color.Yellow)]"
    local body="$(UI.Color.White)${verb} ${description}$(UI.Color.Default)"

    echo "${arrow} ${label} ${body}"
    @return
  }

  # テスト成功時にOKを出力。printInPlace=trueなら開始位置で上書き
  Test.OK() {
    [string] printInPlace=true

    [[ $printInPlace == true ]] && this onStartCursor restore

    # シンボル／色／ラベルをそれぞれ変数化
    local sym  ="$(UI.Color.Green)$(UI.Powerline.OK)"
    local label="$(UI.Color.Yellow)[ $(UI.Color.Green)$(UI.Color.Bold)OK$(UI.Color.NoBold) $(UI.Color.Yellow)]"
    local reset="$(UI.Color.Default)"

    echo "${sym} ${label}${reset}"
    @return
  }

  # OK表示を別形式で呼び出すヘルパー
  Test.EchoedOK() {
    this OK false
  }

  # テスト失敗時にFAILロゴと詳細を出力
  Test.Fail() {
    [string] line
    [string] error
    [string] source
    local sym    ="$(UI.Color.Red)$(UI.Powerline.Fail)"
    local label  ="$(UI.Color.Yellow)[$(UI.Color.Red)$(UI.Color.Bold)FAIL$(UI.Color.NoBold)$(UI.Color.Yellow)]"
    local loc    ="in $(UI.Color.Yellow)${source}$(UI.Color.Default):$(UI.Color.Blue)${line}$(UI.Color.Default)"
    local arrow  ="$(UI.Powerline.RefersTo)"

    echo "${sym} ${label} ${loc} ${arrow} $(UI.Color.Red)${error}$(UI.Color.Default)"
    @return
      }
  }

  # テストグループ終了時に結果サマリを出力
  Test.DisplaySummary() {
    # 共通パーツを変数にまとめる
    local arrow  ="$(UI.Powerline.ArrowLeft)"
    local grp    ="$(UI.Color.White)$(this groupName)"
    local base   ="$(UI.Color.Magenta)Completed [${grp}$(UI.Color.Magenta)]: $(UI.Color.Default)"

    if [[ $(this errors) == true ]]; then
      local status ="$(UI.Color.Red)There were errors $(UI.Color.Default)$(UI.Powerline.Lightning)"
      this errors = false           # フラグをリセット
    else
      local status ="$(UI.Color.Yellow)Test group completed successfully $(UI.Color.Default)$(UI.Powerline.ThumbsUp)"
    fi

    echo "${arrow} ${base}${status}"
    @return
  }


  # 新しいテストグループを開始し、グループ名を設定
  Test.NewGroup() {
    [string] groupName             # グループ名引数

    # 表示用パーツに分解して組み立て
    local arrow ="$(UI.Powerline.ArrowRight)"
    local label="$(UI.Color.Magenta)Testing [$(UI.Color.White)${groupName}$(UI.Color.Magenta)]:"
    echo "${arrow} ${label}$(UI.Color.Default)"

    this groupName = "$groupName"   # プロパティに保持

    @return
  }
}

# 静的クラスの初期化
Type::InitializeStatic Test

### TODO: special case for static classes
### for storage use a generated variable name (hash of class name?)
### for execution use class' name, e.g. Test Start

alias describe='Test NewGroup'
alias summary='Test DisplaySummary'
alias caught="echo \"CAUGHT: $(UI.Color.Red)\$__BACKTRACE_COMMAND__$(UI.Color.Default) in \$__BACKTRACE_SOURCE__:\$__BACKTRACE_LINE__\""
alias it="Test Start it"
alias expectPass="Test OK; catch { Test errors = true; Test Fail \"\${__EXCEPTION__[@]}\"; }"
alias expectOutputPass="Test EchoedOK; catch { Test errors = true; Test Fail; }"
alias expectFail='catch { caught; Test EchoedOK; }; test $? -eq 1 && Test errors = false; '
