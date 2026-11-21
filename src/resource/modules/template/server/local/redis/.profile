# .profile

# Source global definitions
if [ -f /etc/profile ]; then
  . /etc/profile
fi

redis() {
  execute="$1"
  pattern="$2"
  no="${3:-0}"
  shift 3

  case "$execute" in
    -e) sh ~/scripts/redis-clear-keys.sh ex "$pattern" "$no" "$@";;
    -b) sh ~/scripts/redis-clear-keys.sh bk "$pattern" "$no" "$@";;
    -r) sh ~/scripts/redis-clear-keys.sh rb "$pattern" "$no" "$@";;
    -f) sh ~/scripts/redis-clear-keys.sh keys "$pattern" "$no" "$@";;
    -l) sh ~/scripts/redis-clear-keys.sh login "*";;
    *) echo "redis command:$execute not found";;
  esac
}
