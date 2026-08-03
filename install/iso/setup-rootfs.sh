#!/bin/bash

set -euo pipefail

rootfs=${1:?Usage: setup-rootfs.sh ROOTFS}
workspace=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

install -d -m 0755 "$rootfs/opt/omyvoid" "$rootfs/usr/local/bin" \
  "$rootfs/etc/skel/.config" "$rootfs/etc/skel/.config/omyvoid/current" \
  "$rootfs/etc/skel/.config/service" "$rootfs/etc/skel/.local/share" \
  "$rootfs/etc/sddm.conf.d" "$rootfs/usr/share/wayland-sessions" \
  "$rootfs/etc/runit/runsvdir/default"

rsync -a --delete --exclude=.git --exclude=build --exclude=installer/target \
  "$workspace/" "$rootfs/opt/omyvoid/"
install -m 0755 "$workspace/installer/target/release/omyvoid-installer" \
  "$rootfs/usr/local/bin/omyvoid-installer"

for command in "$rootfs/opt/omyvoid/bin"/omyvoid*; do
  [[ -f $command && -x $command ]] || continue
  ln -snf "/opt/omyvoid/bin/${command##*/}" "$rootfs/usr/local/bin/${command##*/}"
done
ln -snf /opt/omyvoid "$rootfs/etc/skel/.local/share/omyvoid"

cp -a "$workspace/config/." "$rootfs/etc/skel/.config/"
install -m 0644 "$workspace/default/bashrc" "$rootfs/etc/skel/.bashrc"
cp -a "$workspace/themes/omyvoid" "$rootfs/etc/skel/.config/omyvoid/current/theme"
printf 'omyvoid\n' > "$rootfs/etc/skel/.config/omyvoid/current/theme.name"
ln -snf theme/backgrounds/omyvoidBackground.png "$rootfs/etc/skel/.config/omyvoid/current/background"

install -m 0644 "$workspace/default/wayland-sessions/omyvoid.desktop" \
  "$rootfs/usr/share/wayland-sessions/omyvoid.desktop"
install -m 0644 "$workspace/default/wayland-sessions/hyprland.desktop" \
  "$rootfs/usr/share/wayland-sessions/hyprland.desktop"
install -d -m 0755 "$rootfs/usr/share/sddm"
install -m 0644 "$workspace/default/sddm/hyprland.conf" "$rootfs/usr/share/sddm/hyprland.conf"
install -d -m 0755 "$rootfs/usr/share/sddm/themes/omyvoid"
cp -a "$workspace/default/sddm/omyvoid/." "$rootfs/usr/share/sddm/themes/omyvoid/"

cat > "$rootfs/etc/sddm.conf.d/99-omyvoid-live.conf" <<'EOF'
[General]
DisplayServer=wayland
DefaultSession=omyvoid

[Wayland]
CompositorCommand=Hyprland --config /usr/share/sddm/hyprland.conf

[Autologin]
User=omyvoid
Session=omyvoid
Relogin=true

[Theme]
Current=omyvoid
EOF

for service in dbus elogind seatd NetworkManager sddm socklog-unix nanoklogd; do
  [[ -d $rootfs/etc/sv/$service ]] || continue
  ln -snf "/etc/sv/$service" "$rootfs/etc/runit/runsvdir/default/$service"
done

install_live_user_service() {
  local name=$1
  shift
  local service="$rootfs/etc/skel/.config/service/$name"
  mkdir -p "$service"
  printf '#!/bin/sh\nexec %s 2>&1\n' "$*" > "$service/run"
  chmod 0755 "$service/run"
}

install_live_user_service pipewire pipewire
install_live_user_service pipewire-pulse pipewire-pulse
install_live_user_service wireplumber wireplumber
install_live_user_service swayosd swayosd-server
install_live_user_service elephant elephant
install_live_user_service walker walker --gapplication-service
