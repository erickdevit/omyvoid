#!/bin/bash

set -euo pipefail

[[ $(findmnt -n -o FSTYPE /) == btrfs ]] || {
  echo "Omyvoid requires a Btrfs root filesystem" >&2
  exit 1
}

sudo install -d -m 0755 /etc/snapper/configs /.snapshots
sudo install -m 0644 "$OMYVOID_PATH/default/snapper/root" /etc/snapper/configs/root
sudo tee /etc/conf.d/snapper >/dev/null <<'EOF'
SNAPPER_CONFIGS="root"
EOF
sudo chmod 0750 /.snapshots
sudo snapper --no-dbus -c root list >/dev/null
