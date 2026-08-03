#!/bin/bash

set -euo pipefail

iso=${1:?Usage: inspect-iso.sh IMAGE.iso}
command -v xorriso >/dev/null || { echo 'xorriso is required' >&2; exit 1; }
[[ -f $iso ]] || { echo "ISO not found: $iso" >&2; exit 1; }

listing=$(xorriso -indev "$iso" -find / -type f -exec lsdl 2>/dev/null)
for required in /boot/limine.conf /boot/limine-uefi.img /boot/vmlinuz /boot/initrd /LiveOS/squashfs.img /repository/x86_64-repodata; do
  grep -Fq "'$required'" <<<"$listing" || {
    echo "Missing ISO artifact: $required" >&2
    exit 1
  }
done

if grep -Eiq '/boot/(grub|isolinux)|/EFI/[^/]*grub' <<<"$listing"; then
  echo 'The final ISO still contains a legacy bootloader tree' >&2
  exit 1
fi

xorriso -indev "$iso" -report_el_torito plain 2>&1 | grep -Eiq 'UEFI|EFI' || {
  echo 'The ISO does not advertise its UEFI boot image' >&2
  exit 1
}

echo "ISO structure is valid: $iso"
