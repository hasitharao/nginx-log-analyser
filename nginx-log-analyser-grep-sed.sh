#!/usr/bin/env bash
#
# nginx-log-analyser-grep-sed.sh  -  Solution 2: grep + sed
#
# Usage: ./nginx-log-analyser-grep-sed.sh [-n COUNT] <logfile>

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

top_n() {
  sort | uniq -c | sort -k1,1nr -k2 | head -n "$TOP_N" |
    sed -E 's/^ *([0-9]+) (.*)$/\2 - \1 requests/; s/ - 1 requests$/ - 1 request/'
}

# IP: everything up to the first space at the start of the line
ips()      { grep -oE '^[^ ]+' "$LOG_FILE"; }
# Path: 2nd word inside the first pair of quotes  ->  "GET /path HTTP/1.1"
paths()    { sed -nE 's/^[^"]*"[A-Z]+ ([^ ]+) [^"]*".*/\1/p' "$LOG_FILE"; }
# Status: 3-digit number right after the closing quote of the request
statuses() { sed -nE 's/^[^"]*"[^"]*" ([0-9]{3}) .*/\1/p' "$LOG_FILE"; }
# User agent: the 6th quoted segment (skip 5 quote characters, capture to the 6th)
agents()   { sed -nE 's/^([^"]*"){5}([^"]+)".*/\2/p' "$LOG_FILE"; }

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
