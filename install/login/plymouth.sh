theme_dir="/usr/share/plymouth/themes/omyvoid"
staging_dir=$(mktemp -d)
trap 'rm -rf "$staging_dir"' EXIT

accent_hex=f59e0b

find "${OMYVOID_PATH:-$HOME/.local/share/omyvoid}/default/plymouth" -maxdepth 1 -type f -exec cp -t "$staging_dir/" {} +
omyvoid-cmd-generate-ascii-logo "$staging_dir/logo.png" "$accent_hex"
magick "${OMYVOID_PATH:-$HOME/.local/share/omyvoid}/icon.png" -bordercolor none -border 40x40 "$staging_dir/spinner.png"
omyvoid-cmd-recolor-image-assets "$staging_dir" "$accent_hex" \
  bullet.png entry.png lock.png

sudo rm -rf "$theme_dir"
sudo mkdir -p "$theme_dir"
sudo cp -a "$staging_dir/." "$theme_dir/"
sudo chown -R root:root "$theme_dir"
sudo find "$theme_dir" -type d -exec chmod 0755 {} +
sudo find "$theme_dir" -type f -exec chmod 0644 {} +

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  sudo plymouth-set-default-theme omyvoid
else
  sudo ln -sfn /usr/share/plymouth/themes/omyvoid/omyvoid.plymouth /usr/share/plymouth/themes/default.plymouth
fi

# Rebuild the UKIs so the custom theme is embedded at boot.
sudo omyvoid-boot-refresh
