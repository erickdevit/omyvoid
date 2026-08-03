#!/bin/bash

set -euo pipefail

repository=${1:?Usage: inspect-xbps-repo.sh REPOSITORY_DIR}
expected_packages=(
  elephant
  omyvoid-dracut-snapshot
  omyvoid-limine-entry-tool
  omyvoid-limine-snapper-sync
)

command -v xbps-query >/dev/null || {
  echo "xbps-query is required" >&2
  exit 1
}
[[ -f $repository/x86_64-repodata ]] || {
  echo "XBPS repository metadata is missing: $repository/x86_64-repodata" >&2
  exit 1
}

shopt -s nullglob
artifacts=("$repository"/*.xbps)
shopt -u nullglob
(( ${#artifacts[@]} == ${#expected_packages[@]} )) || {
  echo "Expected ${#expected_packages[@]} XBPS artifacts, found ${#artifacts[@]}" >&2
  exit 1
}

for package in "${expected_packages[@]}"; do
  xbps-query --repository="$repository" "$package" >/dev/null || {
    echo "Package is missing from the XBPS repository: $package" >&2
    exit 1
  }
done

echo "XBPS repository contains the four expected Omyvoid packages"
