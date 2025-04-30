function checkAppleSilicon() {
  local arch_type
  local is_rosetta
  arch_type=$(arch)
  is_rosetta=$(sysctl -in sysctl.proc_translated 2>/dev/null)

  if [[ "$arch_type" == "arm64" || "$is_rosetta" == "1" ]]; then
    return 0
  else
    return 1
  fi
}

# brewのPATH
if checkAppleSilicon; then
  # arm64
  echo -e "\033]1337;SetProfile=ARM\a"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
else
  # x86_64
  echo -e "\033]1337;SetProfile=Intel\a"
  eval "$(/usr/local/bin/brew shellenv)"
  PATH=/usr/local/bin:/usr/local/sbin:$PATH
fi
