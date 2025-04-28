namespace util
#
# Those values are come from /usr/include/sysexits.h
#

# successful termination
Util_ExitCode_OK=0

Util_ExitCode_USAGE=64  # command line usage error:コマンドラインの使用方法エラー
Util_ExitCode_DATAERR=65  # data format error:
Util_ExitCode_NOINPUT=66  # cannot open input:入力ファイルを開けない
Util_ExitCode_NOUSER=67  # addressee unknown:
Util_ExitCode_NOHOST=68  # host name unknown:
Util_ExitCode_UNAVAILABLE=69  # service unavailable:サービス利用不可
Util_ExitCode_SOFTWARE=70  # internal software error:
Util_ExitCode_OSERR=71  # system error (e.g., can't fork):
Util_ExitCode_OSFILE=72  # critical OS file missing:重大な OS ファイルが存在しない
Util_ExitCode_CANTCREAT=73  # can't create (user) output file:
Util_ExitCode_IOERR=74  # input/output error
Util_ExitCode_TEMPFAIL=75  # temp failure; user is invited to retry:一時的障害（再試行を促す）
Util_ExitCode_PROTOCOL=76  # remote error in protocol:プロトコル上のリモートエラー
Util_ExitCode_NOPERM=77  # permission denied:
Util_ExitCode_CONFIG=78  # configuration error:設定エラー
