namespace util_ext

## IMPORT ##
# ------------------------ #
import util_ext/providers

## MAIN ##
# ------------------------ #
# 指定したアスキーアートに虹色エフェクトをかけて表示する
Lolcat::Ascii() {
  local target=${1:-common}
  local speed=${2:-5}
  local spread=${3:-1.5}
  local seed=${4:-140}
  local target_dir

  case ${target} in
    "common" ) target_dir="$(resourceDir)/${target}";;
            *) target_dir="$(resourceModules)/${target}";;
  esac

  lolcat --speed=$speed --spread=$spread --seed=$seed "${target_dir}/ascii.text"
}

alias printAscii='Lolcat::Ascii'
