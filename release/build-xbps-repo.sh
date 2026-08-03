#!/bin/bash

set -euo pipefail

workspace=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
build_root=${OMYVOID_XBPS_BUILD_DIR:-$workspace/build/xbps}
output=${1:-$workspace/build/repository}
void_packages="$build_root/void-packages"
repo_packages=(
  elephant
  omyvoid-dracut-snapshot
  omyvoid-limine-entry-tool
  omyvoid-limine-snapper-sync
)

case "$build_root" in
  "$workspace"/build/*) ;;
  *) [[ -n ${OMYVOID_XBPS_BUILD_DIR:-} && $build_root != "/" ]] || {
    echo "Refusing unsafe XBPS build directory: $build_root" >&2
    exit 1
  } ;;
esac

case "$output" in
  "$workspace"/build/*) ;;
  *) [[ $output != "/" ]] || { echo "Refusing unsafe repository output: $output" >&2; exit 1; } ;;
esac

for tool in git xbps-rindex; do
  command -v "$tool" >/dev/null || { echo "Missing XBPS build dependency: $tool" >&2; exit 1; }
done
(( EUID != 0 )) || { echo "xbps-src must run as a non-root user" >&2; exit 1; }

mkdir -p "$build_root" "$output"
if [[ -d $void_packages/.git ]]; then
  git -C "$void_packages" pull --ff-only
else
  git clone --depth=1 https://github.com/void-linux/void-packages.git "$void_packages"
fi

for package in "${repo_packages[@]}"; do
  package_dir="$void_packages/srcpkgs/$package"
  rm -rf "$package_dir"
  mkdir -p "$package_dir"
  cp "$workspace/xbps-src/srcpkgs/$package/template" "$package_dir/template"
done

entry_files="$void_packages/srcpkgs/omyvoid-limine-entry-tool/files"
mkdir -p "$entry_files"
cp "$workspace/bin/omyvoid-boot-refresh" "$workspace/bin/omyvoid-boot-repair" \
  "$workspace/bin/omyvoid-boot-cmdline-add" "$workspace/bin/omyvoid-boot-cmdline-remove" \
  "$workspace/bin/omyvoid-boot-snapshot-build" "$workspace/bin/omyvoid-uki-build" "$entry_files/"
cp "$workspace/default/kernel.d/60-omyvoid-limine" "$entry_files/"
cp "$workspace/default/limine/limine.conf" "$workspace/default/limine/omyvoid-boot.png" "$entry_files/"
install -m 0644 "$workspace/LICENSE" "$entry_files/LICENSE"

snapshot_files="$void_packages/srcpkgs/omyvoid-limine-snapper-sync/files"
mkdir -p "$snapshot_files"
cp "$workspace/bin/omyvoid-snapshot" "$workspace/default/snapper/root" \
  "$workspace/config/autostart/omyvoid-snapshot-notify.desktop" "$snapshot_files/"
install -m 0644 "$workspace/LICENSE" "$snapshot_files/LICENSE"

dracut_files="$void_packages/srcpkgs/omyvoid-dracut-snapshot/files"
mkdir -p "$dracut_files"
cp "$workspace/default/dracut/95omyvoid-snapshot-overlay/"* "$dracut_files/"
install -m 0644 "$workspace/LICENSE" "$dracut_files/LICENSE"

pushd "$void_packages" >/dev/null
./xbps-src binary-bootstrap
for package in "${repo_packages[@]}"; do
  find hostdir/binpkgs -maxdepth 1 -type f -name "${package}-*.xbps" -delete
  ./xbps-src pkg "$package"
done
popd >/dev/null

find "$output" -maxdepth 1 -type f -name '*.xbps' -delete
find "$output" -maxdepth 1 -type f -name '*-repodata*' -delete
shopt -s nullglob
for package in "${repo_packages[@]}"; do
  artifacts=("$void_packages/hostdir/binpkgs/${package}-"*.xbps)
  (( ${#artifacts[@]} > 0 )) || {
    echo "No XBPS artifact was produced for $package" >&2
    exit 1
  }
  cp "${artifacts[@]}" "$output/"
done
shopt -u nullglob
xbps-rindex -a "$output/"*.xbps

if [[ -n ${OMYVOID_XBPS_SIGNING_KEY:-} ]]; then
  xbps-rindex --sign --signedby "Omyvoid Release" --privkey "$OMYVOID_XBPS_SIGNING_KEY" "$output"
  xbps-rindex --sign-pkg --privkey "$OMYVOID_XBPS_SIGNING_KEY" "$output/"*.xbps
fi

echo "Built Omyvoid XBPS repository at $output"
