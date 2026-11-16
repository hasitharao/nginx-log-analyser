#!/usr/bin/env bash
#
# nginx-log-analyser-awk.sh  -  Solution 3: one pass, pure awk
#
# Usage: ./nginx-log-analyser-awk.sh [-n COUNT] <logfile>

set -eu
export LC_ALL=C

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

awk -F'"' -v n="$TOP_N" '
# Print the n biggest entries of cnt (ties broken alphabetically).
function top(title, cnt,    i, k, best, bc) {
  print title
  for (i = 1; i <= n; i++) {
    bc = 0; best = ""
    for (k in cnt)
      if (cnt[k] > bc || (cnt[k] == bc && k < best)) { bc = cnt[k]; best = k }
    if (bc == 0) break
    printf "%s - %d request%s\n", best, bc, (bc == 1 ? "" : "s")
    delete cnt[best]
  }
}

{
  split($1, a, " ");  if (a[1] != "") ip[a[1]]++
  split($2, r, " ");  if (r[2] != "") path[r[2]]++
  split($3, s, " ");  if (s[1] != "") status[s[1]]++
  if ($6 != "") agent[$6]++
}

END {
  top("Top " n " IP addresses with the most requests:", ip);   print ""
  top("Top " n " most requested paths:", path);                print ""
  top("Top " n " response status codes:", status);             print ""
  top("Top " n " user agents:", agent)
}
' "$LOG_FILE"
