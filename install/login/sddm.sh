# Install omyvoid SDDM theme
omyvoid-refresh-sddm

# Setup SDDM login service
sudo mkdir -p /usr/share/wayland-sessions
sudo cp "$OMYVOID_PATH/default/wayland-sessions/omyvoid.desktop" /usr/share/wayland-sessions/omyvoid.desktop
sudo cp "$OMYVOID_PATH/default/wayland-sessions/hyprland.desktop" /usr/share/wayland-sessions/hyprland.desktop
sudo cp "$OMYVOID_PATH/default/sddm/hyprland.conf" /usr/share/sddm/hyprland.conf
sudo rm -f /usr/share/sddm/hyprland.lua

sudo mkdir -p /etc/sddm.conf.d
# Remove old local overrides.
sudo rm -f /etc/sddm.conf.d/10-wayland.conf
sudo rm -f /etc/sddm.conf.d/autologin.conf
sudo rm -f /etc/sddm.conf.d/zz-omyvoid-live.conf

sddm_autologin_block=""
# Live ISO uses zz-omyvoid-live.conf; chroot installs are finalized after user creation.
if [[ -z ${OMYVOID_ISO_BUILD:-} && -z ${OMYVOID_CHROOT_INSTALL:-} ]]; then
  omyvoid_encrypted_install=false
  if [[ ${OMYVOID_ENCRYPTED_INSTALL:-} == "true" ]]; then
    omyvoid_encrypted_install=true
  elif [[ -f /etc/crypttab ]] && grep -qE '^[^#[:space:]]' /etc/crypttab; then
    omyvoid_encrypted_install=true
  fi

  if [[ $omyvoid_encrypted_install == true ]]; then
    autologin_user="${USER:-}"
    if [[ $autologin_user == "root" && -n ${SUDO_USER:-} ]]; then
      autologin_user="$SUDO_USER"
    fi
    if [[ -n $autologin_user && $autologin_user != "root" ]]; then
      sddm_autologin_block="
[Autologin]
User=$autologin_user
Session=omyvoid
Relogin=true"
    fi
  fi
fi

cat <<EOF | sudo tee /etc/sddm.conf.d/99-omyvoid.conf >/dev/null
[General]
DisplayServer=wayland
DefaultSession=omyvoid

[Wayland]
CompositorCommand=Hyprland --config /usr/share/sddm/hyprland.conf
$sddm_autologin_block

[Theme]
Current=omyvoid
EOF

sudo sed -i '/pam_faillock\.so/d' /etc/pam.d/sddm-autologin 2>/dev/null || true

# Prevent password-based SDDM logins from creating an encrypted login keyring
# (which conflicts with the passwordless Default_keyring used for auto-unlock)
sudo sed -i '/-auth.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm
sudo sed -i '/-password.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm

chrootable_runit_enable sddm
