#!/usr/bin/env bash
#
# nginx-log-analyser.sh  -  Solution 1: awk + sort + uniq + head
#
# Usage: ./nginx-log-analyser.sh [-n COUNT] <logfile>

set -eu
export LC_ALL=C   # byte-wise sort: faster and identical on macOS and Linux

TOP_N=5

usage() {
  echo "Usage: ${0##*/} [-n COUNT] <logfile>" >&2
  exit 1
}

while getopts ":n:" opt; do
  case "$opt" in
    n) TOP_N="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

[ $# -eq 1 ] || usage
LOG_FILE="$1"

[ -f "$LOG_FILE" ] || { echo "Error: '$LOG_FILE' is not a file" >&2; exit 1; }
[ -r "$LOG_FILE" ] || { echo "Error: '$LOG_FILE' is not readable" >&2; exit 1; }
case "$TOP_N" in
  ''|*[!0-9]*|0) echo "Error: -n must be a positive integer" >&2; exit 1 ;;
esac

# Reads one value per line on stdin, prints the TOP_N most frequent as
# "<value> - <count> requests".
top_n() {
  sort | uniq -c | sort -k1,1nr -k2 | head -n "$TOP_N" |
    awk '{
      c = $1
      sub(/^ *[0-9]+ /, "")
      printf "%s - %d request%s\n", $0, c, (c == 1 ? "" : "s")
    }'
}

# Splitting on the double quote keeps fields stable even when the user agent
# contains spaces: $1 = IP/date, $2 = request, $3 = status/size, $6 = user agent
ips()      { awk '{ print $1 }' "$LOG_FILE"; }
paths()    { awk -F'"' '{ split($2, r, " "); if (r[2] != "") print r[2] }' "$LOG_FILE"; }
statuses() { awk -F'"' '{ split($3, s, " "); if (s[1] != "") print s[1] }' "$LOG_FILE"; }
agents()   { awk -F'"' '{ if ($6 != "") print $6 }' "$LOG_FILE"; }

echo "Top $TOP_N IP addresses with the most requests:"
ips | top_n
echo
echo "Top $TOP_N most requested paths:"
paths | top_n
echo
echo "Top $TOP_N response status codes:"
statuses | top_n
echo
echo "Top $TOP_N user agents:"
agents | top_n
