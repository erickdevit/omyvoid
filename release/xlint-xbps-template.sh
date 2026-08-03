#!/bin/bash

set -euo pipefail

template=${1:?Usage: xlint-xbps-template.sh TEMPLATE}
raw_output=''
output=''
status=0

raw_output=$(xlint "$template" 2>&1) || status=$?
# Omyvoid requires two-space indentation in every shell source, including XBPS
# templates. Preserve every other xlint diagnostic and ignore only that conflict.
output=$(grep -v -E ': please indent with tabs$' <<<"$raw_output" || true)

if [[ -n $output ]]; then
  printf '%s\n' "$output" >&2
  exit "$status"
fi

if (( status > 1 )) || (( status != 0 )) && [[ -z $raw_output ]]; then
  echo "xlint failed without an actionable diagnostic for $template" >&2
  exit "$status"
fi
