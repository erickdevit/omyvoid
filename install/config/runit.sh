#!/bin/bash

set -euo pipefail

for service in dbus elogind seatd socklog-unix nanoklogd NetworkManager chronyd snapperd; do
  [[ -d /etc/sv/$service ]] || continue
  chrootable_runit_enable "$service"
done

for service in /etc/sv/zramen*; do
  [[ -d $service ]] || continue
  chrootable_runit_enable "${service##*/}"
done

sudo install -d -m 0755 /etc/sv/omyvoid-plocate
sudo tee /etc/sv/omyvoid-plocate/run >/dev/null <<'EOF'
#!/bin/sh
exec 2>&1
exec snooze -H 4 -m 30 -r 15 -- sh -c '
  if command -v omyvoid-ac-connected >/dev/null 2>&1 && ! omyvoid-ac-connected; then
    exit 0
  fi
  exec updatedb
'
EOF
sudo chmod 0755 /etc/sv/omyvoid-plocate/run
chrootable_runit_enable omyvoid-plocate

mkdir -p "$HOME/.config/service"

install_user_service() {
  local name=$1
  shift
  local service="$HOME/.config/service/$name"
  mkdir -p "$service"
  printf '#!/bin/sh\nexec %s 2>&1\n' "$*" > "$service/run"
  chmod 0755 "$service/run"
}

install_user_service pipewire pipewire
install_user_service pipewire-pulse pipewire-pulse
install_user_service wireplumber wireplumber
install_user_service swayosd swayosd-server
install_user_service elephant elephant
install_user_service walker walker --gapplication-service
