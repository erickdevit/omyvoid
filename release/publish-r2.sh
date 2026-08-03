#!/bin/bash

set -euo pipefail

iso=${1:?Usage: publish-r2.sh IMAGE.iso REPOSITORY_DIR}
repository=${2:?Usage: publish-r2.sh IMAGE.iso REPOSITORY_DIR}
version=${OMYVOID_RELEASE_VERSION:-$(basename "$iso" | sed -E 's/^omyvoid-(.*)-x86_64\.iso$/\1/')}

for variable in R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_ACCOUNT_ID R2_BUCKET OMYVOID_R2_PUBLIC_URL OMYVOID_XBPS_PUBLIC_URL OMYVOID_MINISIGN_PUBLIC_KEY_FILE; do
  [[ -n ${!variable:-} ]] || { echo "Missing release variable: $variable" >&2; exit 1; }
done
for tool in curl minisign rclone sha256sum; do
  command -v "$tool" >/dev/null || { echo "Missing release dependency: $tool" >&2; exit 1; }
done
[[ -f $iso && -f $iso.sha256 && -f $iso.minisig ]] || {
  echo "ISO, checksum and Minisign signature must exist together" >&2
  exit 1
}
[[ -f $repository/x86_64-repodata ]] || {
  echo "Signed XBPS repository metadata is missing: $repository/x86_64-repodata" >&2
  exit 1
}

export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_R2_ENDPOINT="https://$R2_ACCOUNT_ID.r2.cloudflarestorage.com"

release_prefix="r2:$R2_BUCKET/releases/$version"
rclone copyto "$iso" "$release_prefix/$(basename "$iso")"
rclone copyto "$iso.sha256" "$release_prefix/$(basename "$iso.sha256")"
rclone copyto "$iso.minisig" "$release_prefix/$(basename "$iso.minisig")"
rclone sync "$repository" "r2:$R2_BUCKET/current"

verification_dir=$(mktemp -d)
trap 'rm -rf "$verification_dir"' EXIT
public_release="${OMYVOID_R2_PUBLIC_URL%/}/releases/$version"
public_repository="${OMYVOID_XBPS_PUBLIC_URL%/}"
for artifact in "$(basename "$iso")" "$(basename "$iso.sha256")" "$(basename "$iso.minisig")"; do
  curl --fail --location --retry 5 --output "$verification_dir/$artifact" "$public_release/$artifact"
done
curl --fail --location --retry 5 --output "$verification_dir/x86_64-repodata" \
  "$public_repository/x86_64-repodata"

(
  cd "$verification_dir"
  sha256sum --check "$(basename "$iso.sha256")"
  minisign -Vm "$(basename "$iso")" -x "$(basename "$iso.minisig")" -p "$OMYVOID_MINISIGN_PUBLIC_KEY_FILE"
)

echo "Published and verified Omyvoid $version from $public_release"
