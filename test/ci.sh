#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scripts=()
actionlint_version=1.7.12
actionlint_archive="actionlint_${actionlint_version}_linux_amd64.tar.gz"
actionlint_sha256=8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
actionlint_dir=$(mktemp -d)
trap 'rm -rf "$actionlint_dir"' EXIT

while IFS= read -r script; do
  [[ $(head -n 1 "$script") == *python* ]] && continue
  scripts+=("$script")
done < <(find "$root/bin" "$root/install" "$root/release" "$root/test" \
  -type f \( -name '*.sh' -o -path "$root/bin/omyvoid*" \))

shellcheck -S error -s bash -e SC1090,SC1091 "${scripts[@]}"

curl --fail --location --silent --show-error \
  --output "$actionlint_dir/$actionlint_archive" \
  "https://github.com/rhysd/actionlint/releases/download/v$actionlint_version/$actionlint_archive"
(
  cd "$actionlint_dir"
  printf '%s  %s\n' "$actionlint_sha256" "$actionlint_archive" | sha256sum --check --status
  tar -xzf "$actionlint_archive"
)
"$actionlint_dir/actionlint" \
  "$root/.github/workflows/ci.yml" \
  "$root/.github/workflows/release.yml"

python3 - "$root" <<'PY'
from pathlib import Path
import sys

import yaml

root = Path(sys.argv[1])
for relative_path in (
  ".github/actionlint.yaml",
  ".github/workflows/ci.yml",
  ".github/workflows/release.yml",
  ".gitlab-ci.yml",
):
  with (root / relative_path).open(encoding="utf-8") as stream:
    yaml.safe_load(stream)
PY

"$root/test/run.sh"

cargo fmt --manifest-path "$root/installer/Cargo.toml" -- --check
cargo clippy --locked --manifest-path "$root/installer/Cargo.toml" --all-targets -- -D warnings
cargo test --locked --manifest-path "$root/installer/Cargo.toml"

for template in "$root"/xbps-src/srcpkgs/*/template; do
  xlint "$template"
done
