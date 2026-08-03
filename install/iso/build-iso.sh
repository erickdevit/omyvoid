#!/bin/bash

set -euo pipefail

workspace=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
build_dir=${OMYVOID_BUILD_DIR:-$workspace/build/iso}
output=${1:-$workspace/build/omyvoid-$(cat "$workspace/version")-x86_64.iso}
void_mklive="$build_dir/void-mklive"
stage_iso="$build_dir/void-stage.iso"
image_dir="$build_dir/image"
repository_dir="$build_dir/repository"
efi_image="$image_dir/boot/limine-uefi.img"
repository_args=(
  -r https://repo-default.voidlinux.org/current/nonfree
  -r https://repo-default.voidlinux.org/current/multilib
  -r https://repo-default.voidlinux.org/current/multilib/nonfree
  -r https://mirror.black-hole.dev/x86_64
  -r "$repository_dir"
)
if [[ -n ${OMYVOID_XBPS_REPOSITORY:-} ]]; then
  repository_args+=(-r "$OMYVOID_XBPS_REPOSITORY")
fi
export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git -C "$workspace" show -s --format=%ct HEAD 2>/dev/null || date +%s)}

case "$build_dir" in
  "$workspace"/build/*) ;;
  *) [[ -n ${OMYVOID_BUILD_DIR:-} && $build_dir != "/" ]] || {
    echo "Refusing unsafe ISO build directory: $build_dir" >&2
    exit 1
  } ;;
esac
[[ $(dirname "$image_dir") == "$build_dir" && $(dirname "$repository_dir") == "$build_dir" ]] || {
  echo "ISO staging paths must remain directly below $build_dir" >&2
  exit 1
}
(( EUID != 0 )) || {
  echo "Build the ISO as a regular user; xbps-src refuses root builds" >&2
  exit 1
}

for tool in cargo git xbps-install xbps-rindex xorriso mformat mmd mcopy truncate; do
  command -v "$tool" >/dev/null || {
    echo "Missing ISO build dependency: $tool" >&2
    exit 1
  }
done
[[ -f /usr/share/limine/BOOTX64.EFI ]] || {
  echo "Install the Void limine package before building the ISO" >&2
  exit 1
}

mkdir -p "$build_dir" "$(dirname "$output")"
if [[ -d $void_mklive/.git ]]; then
  git -C "$void_mklive" pull --ff-only
else
  git clone --depth=1 https://github.com/void-linux/void-mklive.git "$void_mklive"
fi

cargo build --locked --release --manifest-path "$workspace/installer/Cargo.toml"
OMYVOID_XBPS_SIGNING_KEY='' "$workspace/release/build-xbps-repo.sh" "$repository_dir"
mapfile -t packages < <(sed -E 's/[[:space:]]*#.*$//' "$workspace/install/omyvoid-base.packages" | awk 'NF')

pushd "$void_mklive" >/dev/null
./mklive.sh \
  -a x86_64 \
  -T Omyvoid \
  -o "$stage_iso" \
  -c "$build_dir/xbps-cache" \
  "${repository_args[@]}" \
  -p "${packages[*]}" \
  -S "dbus elogind seatd NetworkManager sddm socklog-unix nanoklogd" \
  -C "live.autologin live.user=omyvoid live.shell=/bin/bash" \
  -x "$workspace/install/iso/setup-rootfs.sh"
popd >/dev/null

rm -rf "$image_dir"
mkdir -p "$image_dir"
xorriso -osirrox on -indev "$stage_iso" -extract / "$image_dir"
rm -rf "$image_dir/boot/grub" "$image_dir/boot/isolinux" "$image_dir/EFI"

shopt -s nullglob
cached_packages=("$build_dir/xbps-cache/"*.xbps)
(( ${#cached_packages[@]} > 0 )) || {
  echo "void-mklive did not populate the offline XBPS cache" >&2
  exit 1
}
cp "${cached_packages[@]}" "$repository_dir/"
find "$repository_dir" -maxdepth 1 -type f ! -name '*.xbps' -delete
repository_packages=("$repository_dir/"*.xbps)
xbps-rindex -a "${repository_packages[@]}"
if [[ -n ${OMYVOID_XBPS_SIGNING_KEY:-} ]]; then
  xbps-rindex --sign --signedby "Omyvoid Release" --privkey "$OMYVOID_XBPS_SIGNING_KEY" "$repository_dir"
  xbps-rindex --sign-pkg --privkey "$OMYVOID_XBPS_SIGNING_KEY" "$repository_dir"/*.xbps
elif [[ ${OMYVOID_RELEASE_BUILD:-false} == true ]]; then
  echo "OMYVOID_XBPS_SIGNING_KEY is required for release builds" >&2
  exit 1
fi
mkdir -p "$image_dir/repository"
cp -a "$repository_dir/." "$image_dir/repository/"

install -m 0644 "$workspace/install/iso/limine.conf" "$image_dir/boot/limine.conf"
install -m 0644 "$workspace/default/limine/omyvoid-boot.png" "$image_dir/boot/omyvoid-boot.png"
truncate -s 32M "$efi_image"
mformat -i "$efi_image" -F -v OMYVOID_EFI ::
mmd -i "$efi_image" ::/EFI ::/EFI/BOOT
mcopy -i "$efi_image" /usr/share/limine/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI

xorriso -as mkisofs \
  -iso-level 3 -rock -joliet -joliet-long -max-iso9660-filenames \
  -volid OMYVOID_LIVE \
  -eltorito-alt-boot -e boot/limine-uefi.img -no-emul-boot \
  -isohybrid-gpt-basdat \
  -output "$output" "$image_dir"

(cd "$(dirname "$output")" && sha256sum "$(basename "$output")" > "$(basename "$output").sha256")
if [[ -n ${OMYVOID_MINISIGN_KEY:-} ]]; then
  command -v minisign >/dev/null || { echo "minisign is required to sign the ISO" >&2; exit 1; }
  minisign -S -s "$OMYVOID_MINISIGN_KEY" -m "$output"
elif [[ ${OMYVOID_RELEASE_BUILD:-false} == true ]]; then
  echo "OMYVOID_MINISIGN_KEY is required for release builds" >&2
  exit 1
fi

echo "Built $output"
