# Starting the installer with OMYVOID_CHROOT_INSTALL=1 will put it into chroot mode.
chrootable_runit_enable() {
  local service=${1%.service}
  local source="/etc/sv/$service"
  local target="/var/service/$service"

  if [[ ! -d $source ]]; then
    echo "Runit service not found: $source" >&2
    return 1
  fi

  sudo mkdir -p /var/service
  sudo ln -snf "$source" "$target"
  if [[ -z ${OMYVOID_CHROOT_INSTALL:-} ]]; then
    sudo sv up "$service" || true
  fi
}

# Export the function so it's available in subshells
export -f chrootable_runit_enable
