#!/bin/bash

set -euo pipefail

[[ -f /etc/default/limine ]] && source /etc/default/limine

boot_fstype=$(findmnt -n -o FSTYPE /boot)
[[ $boot_fstype == vfat ]] || {
  echo "Omyvoid requires a FAT32 filesystem mounted at /boot" >&2
  exit 1
}

root_fstype=$(findmnt -n -o FSTYPE /)
[[ $root_fstype == btrfs ]] || {
  echo "Omyvoid requires a Btrfs root filesystem" >&2
  exit 1
}

root_source=$(findmnt -n -o SOURCE /)
root_uuid=$(findmnt -n -o UUID /)
luks_uuid=""

if [[ $root_source == /dev/mapper/* ]]; then
  mapper=${root_source#/dev/mapper/}
  backing=$(sudo cryptsetup status "$mapper" | awk -F: '$1 ~ /^[[:space:]]*device$/ {gsub(/^[[:space:]]+/, "", $2); print $2}')
  [[ -n $backing ]] || {
    echo "Unable to determine the LUKS backing device for $root_source" >&2
    exit 1
  }
  luks_uuid=$(sudo cryptsetup luksUUID "$backing")
  root_uuid=$(sudo blkid -s UUID -o value "$root_source")
fi

windows_uuid=${OMYVOID_WINDOWS_EFI_UUID:-}
if [[ -z $windows_uuid ]]; then
  while read -r source target; do
    [[ -f $target/EFI/Microsoft/Boot/bootmgfw.efi ]] || continue
    windows_uuid=$(blkid -s UUID -o value "$source")
    break
  done < <(findmnt -rn -t vfat -o SOURCE,TARGET)
fi

sudo install -d -m 0755 /etc/default /etc/dracut.conf.d \
  /usr/lib/dracut/modules.d/95omyvoid-snapshot-overlay \
  /etc/kernel.d/post-install /etc/kernel.d/post-remove \
  /boot/EFI/Omyvoid

sudo tee /etc/default/limine >/dev/null <<EOF
ESP_PATH="/boot"
OMYVOID_ROOT_SUBVOLUME="@"
OMYVOID_ROOT_UUID="$root_uuid"
OMYVOID_LUKS_UUID="$luks_uuid"
OMYVOID_KERNEL_CMDLINE="rw quiet splash loglevel=3 rd.udev.log_level=3"
OMYVOID_WINDOWS_EFI_UUID="$windows_uuid"
OMYVOID_WINDOWS_EFI_PATH="/EFI/Microsoft/Boot/bootmgfw.efi"
OMYVOID_KEEP_SNAPSHOTS=5
EOF

sudo cp -a "$OMYVOID_PATH/default/dracut/95omyvoid-snapshot-overlay/." \
  /usr/lib/dracut/modules.d/95omyvoid-snapshot-overlay/
sudo tee /etc/dracut.conf.d/60-omyvoid.conf >/dev/null <<'EOF'
uefi="yes"
add_dracutmodules+=" crypt btrfs overlayfs omyvoid-snapshot-overlay "
EOF

sudo install -m 0755 "$OMYVOID_PATH/default/kernel.d/60-omyvoid-limine" \
  /etc/kernel.d/post-install/60-omyvoid-limine
sudo install -m 0755 "$OMYVOID_PATH/default/kernel.d/60-omyvoid-limine" \
  /etc/kernel.d/post-remove/60-omyvoid-limine
sudo install -m 0644 "$OMYVOID_PATH/default/limine/omyvoid-boot.png" \
  /boot/EFI/Omyvoid/omyvoid-boot.png

sudo omyvoid-boot-repair
