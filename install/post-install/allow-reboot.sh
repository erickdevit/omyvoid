# Allow passwordless reboot for the installer - removed in first-run
# In ISO builds the chroot user is root, but the live session user is 'omyvoid'
SUDOERS_USER="${OMYVOID_TARGET_USER:-}"
if [[ -z $SUDOERS_USER && -n ${OMYVOID_ISO_BUILD:-} ]]; then
  SUDOERS_USER="omyvoid"
fi
SUDOERS_USER="${SUDOERS_USER:-$USER}"

sudo tee /etc/sudoers.d/99-omyvoid-installer-reboot > /dev/null <<EOF
$SUDOERS_USER ALL=(ALL) NOPASSWD: /usr/bin/reboot
EOF
sudo chmod 440 /etc/sudoers.d/99-omyvoid-installer-reboot
