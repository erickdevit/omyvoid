if sudo test -f /etc/sudoers.d/99-omyvoid-installer-reboot; then
  sudo rm -f /etc/sudoers.d/99-omyvoid-installer-reboot
fi

if sudo test -f /etc/sudoers.d/99-omyvoid-live-installer; then
  sudo rm -f /etc/sudoers.d/99-omyvoid-live-installer
fi
