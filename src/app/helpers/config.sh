namespace helpers
set -e

## IMPORT ##
# ------------------------ #
import util/class
import util_ext/log
import util_ext/yml
import util_ext/json
import util_ext/grep
import util_ext/providers

## MAIN ##
# ------------------------ #
# JSON または YAML の設定ファイルを読み込み、操作するクラス
class:Config() {
  private string config_path
  private string root_key
  private string extension

  # コンストラクタ
  Config.__constructor__() {
    this config_path = "$1"
    this extension = ""

    # ファイル名に拡張子が含まれない場合は json をデフォルトとする
    if [[ $(echo "$(this config_path)" | grep -c -E "\.[a-z]*$") -eq 0 ]]; then
       this config_path = "$(configDir)/$(this config_path).json"
    fi

    this extension = "$(echo "$(this config_path)" | gsed -re "s/^.*\.//")"

    if [[ ! -f "$(this config_path)" ]]; then
      outputErrorLog "not found target_file: $(this config_path)"
    fi

    # 拡張子が json と yml のいずれでもない場合はエラーを出力する
    if [[ $(this extension) != "json" && $(this extension) != "yml" ]]; then
      outputErrorLog "supported　config file is json or yml: $(this default_path)"
    fi

    this root_key = "$2"
  }

  # ファイル内のキー一覧を取得するメソッド
  Config.GetKeys() {
    local key="$1"

    case $(this extension) in
      "json") jsonGetKeys "$(this config_path)" "$(this root_key).$key";;
      "yaml") ymlGetKeys "$(this config_path)" "$(this root_key).$key";;
    esac
  }

  # ファイル内の特定キーの値を取得するメソッド
  Config.Get() {
    local key="$1"

    case $(this extension) in
      "json") jsonGetValue "$(this config_path)" "$(this root_key).$key";;
      "yaml") ymlGetValue "$(this config_path)" "$(this root_key).$key";;
    esac
  }

  # 配列として定義されている値を文字列化して取得するメソッド
  Config.GetArrayToString() {
    local key="$1"

    case $(this extension) in
      "json") jsonGetArrayToString "$(this config_path)" "$(this root_key).$key";;
      "yaml") ymlGetArrayToString "$(this config_path)" "$(this root_key).$key";;
    esac
  }
}

Type::Initialize Config
