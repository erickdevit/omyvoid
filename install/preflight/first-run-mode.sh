# Set first-run mode marker so we can install stuff post-installation
mkdir -p ~/.local/state/omyvoid
touch ~/.local/state/omyvoid/first-run.mode

# In ISO builds the chroot user is root, but the live session user is 'omyvoid'
# For regular installs, $USER is the actual user running the script
SUDOERS_USER="${OMYVOID_TARGET_USER:-}"
if [[ -z $SUDOERS_USER && -n ${OMYVOID_ISO_BUILD:-} ]]; then
  SUDOERS_USER="omyvoid"
fi
SUDOERS_USER="${SUDOERS_USER:-$USER}"

# Setup sudo-less access for first-run
sudo tee /etc/sudoers.d/first-run > /dev/null <<EOF
Cmnd_Alias FIRST_RUN_CLEANUP = /bin/rm -f /etc/sudoers.d/first-run
$SUDOERS_USER ALL=(ALL) NOPASSWD: /usr/bin/ufw
$SUDOERS_USER ALL=(ALL) NOPASSWD: /usr/bin/ufw-docker
$SUDOERS_USER ALL=(ALL) NOPASSWD: /usr/bin/gtk-update-icon-cache
$SUDOERS_USER ALL=(ALL) NOPASSWD: FIRST_RUN_CLEANUP
EOF
sudo chmod 440 /etc/sudoers.d/first-run
