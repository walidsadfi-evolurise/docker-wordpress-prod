#!/bin/sh
# Quick before/after latency check on the home page and the Store API.
# Usage: scripts/bench.sh https://shop.example.com [requests]
set -eu
BASE="${1:?usage: bench.sh <url> [requests]}"
N="${2:-20}"

measure() {
  url="$1"; label="$2"; total=0; min=999; max=0; cache=""
  i=0
  while [ "$i" -lt "$N" ]; do
    out="$(curl -s -o /dev/null -w '%{time_total} %{http_code}' -H 'Accept: text/html' "$url")"
    t="$(echo "$out" | cut -d' ' -f1)"
    ms="$(awk "BEGIN{printf \"%d\", $t*1000}")"
    total=$((total + ms)); [ "$ms" -lt "$min" ] && min=$ms; [ "$ms" -gt "$max" ] && max=$ms
    i=$((i + 1))
  done
  cache="$(curl -s -o /dev/null -D - "$url" | awk -F': ' 'tolower($1)=="x-cache"{print $2}' | tr -d '\r')"
  printf '%-22s avg %4d ms  min %4d  max %4d  x-cache=%s\n' "$label" "$((total / N))" "$min" "$max" "${cache:-n/a}"
}

echo "bench: ${N} requests each against ${BASE}"
measure "${BASE}/" "home page"
measure "${BASE}/wp-json/wc/store/v1/products?per_page=10" "store api (uncached)"
measure "${BASE}/wp-json/" "rest index"
