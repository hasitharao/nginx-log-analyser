# Nginx Log Analyser

A small command-line tool that summarises an nginx access log: top IP addresses, requested paths, response status codes and user agents. Built for the [roadmap.sh Nginx Log Analyser project](https://roadmap.sh/projects/nginx-log-analyser), in three different ways.

## Usage

```bash
curl -L -o nginx-access.log "https://gist.githubusercontent.com/nilbuild/e66c3b9ea89a1a030d3b739eeeef22d0/raw/77fb3ac837a73c4f0206e78a236d885590b7ae35/nginx-access.log"
chmod +x *.sh
./nginx-log-analyser.sh nginx-access.log        # top 5 of everything
./nginx-log-analyser.sh -n 10 nginx-access.log  # top 10 instead
```

Expects nginx's default `combined` log format. Works on macOS (BSD tools, bash 3.2) and Linux.

## Sample output

```
Top 5 IP addresses with the most requests:
138.68.248.85 - 1087 requests
142.93.136.176 - 1087 requests
178.128.94.113 - 1087 requests
159.89.185.30 - 1086 requests
86.134.118.70 - 277 requests

Top 5 most requested paths:
/v1-health - 4560 requests
/ - 270 requests
/v1-me - 232 requests
/v1-list-workspaces - 127 requests
/v1-list-timezone-teams - 75 requests

Top 5 response status codes:
200 - 5740 requests
404 - 937 requests
304 - 621 requests
400 - 260 requests
403 - 23 requests

Top 5 user agents:
DigitalOcean Uptime Probe 0.22.0 (https://digitalocean.com) - 4347 requests
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 - 513 requests
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 - 332 requests
Custom-AsyncHttpClient - 294 requests
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 - 282 requests
```

## Three solutions, same output

| Script | Tools | Passes over the file |
|---|---|---|
| `nginx-log-analyser.sh` | awk, sort, uniq, head | 4 |
| `nginx-log-analyser-grep-sed.sh` | grep, sed, sort, uniq, head | 4 |
| `nginx-log-analyser-awk.sh` | pure awk (associative arrays) | 1 |

All three produce byte-identical output on the sample log (checked with `diff`). The single-pass awk version is the one to reach for on very large logs.

## Design notes

- **Fields are split on the double quote**, not on whitespace, so `$2` is always the request and `$6` the user agent, even though user agents contain spaces.
- **`LC_ALL=C`** gives byte-wise sorting, which is faster and gives the same results on macOS and Linux.
- **Deterministic ties**: equal counts are ordered alphabetically, so output is stable and easy to diff.
- **Portable flags only**: no `grep -P`, no GNU-only options, no bash 4 features.
- **No `set -o pipefail`**: `sort | head -n 5` can receive SIGPIPE once `head` exits, which would abort the script under pipefail.
- Malformed requests (for example `"-"` from port scanners) and blank lines are skipped rather than counted.

## What the sample log shows

The top four IPs (1087 + 1087 + 1087 + 1086 = 4347) add up exactly to the DigitalOcean Uptime Probe user agent count, and `/v1-health` is the most requested path by a wide margin. So most of this log is health-check traffic; real user traffic starts further down the lists.
