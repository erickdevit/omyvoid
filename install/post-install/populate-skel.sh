echo "Populating /etc/skel with user configuration files"

mkdir -p /etc/skel/.config /etc/skel/.local/share /etc/skel/.local/state/omyvoid

if [[ -d /root/.config ]]; then
  cp -a /root/.config/. /etc/skel/.config/
fi

if [[ -d /root/.local/share ]]; then
  cp -a /root/.local/share/. /etc/skel/.local/share/
fi

if [[ -d /root/.local/state/omyvoid ]]; then
  mkdir -p /etc/skel/.local/state
  cp -a /root/.local/state/omyvoid /etc/skel/.local/state/omyvoid
fi

if [[ -d /root/.local/bin ]]; then
  mkdir -p /etc/skel/.local/bin
  cp -a /root/.local/bin/. /etc/skel/.local/bin/
fi

if [[ -f /root/.bashrc ]]; then
  cp /root/.bashrc /etc/skel/.bashrc
fi

# Ensure correct links/pathing for Omyvoid share
mkdir -p /etc/skel/.local/share
ln -snf /opt/omyvoid /etc/skel/.local/share/omyvoid

# Remove socket/lock files if any
rm -rf /etc/skel/.config/chromium/SingletonLock
rm -rf /etc/skel/.config/google-chrome/SingletonLock

# Waybar, mako and hypridle are started by the Omyvoid Hyprland session.
