# Omyvoid v1 supports only Void Linux x86_64-glibc in UEFI mode.
if [[ ! -f /etc/os-release ]] || ! grep -Eq '^ID="?void"?$' /etc/os-release; then
  printf '\e[31mOmyvoid requires Void Linux.\e[0m\n' >&2
  exit 1
fi

if [[ $(uname -m) != "x86_64" ]] || ! getconf GNU_LIBC_VERSION &>/dev/null; then
  printf '\e[31mOmyvoid requires Void Linux x86_64-glibc.\e[0m\n' >&2
  exit 1
fi

if [[ ! -d /sys/firmware/efi ]]; then
  printf '\e[31mOmyvoid requires an UEFI boot. Legacy BIOS is not supported.\e[0m\n' >&2
  exit 1
fi

for secure_boot_variable in /sys/firmware/efi/efivars/SecureBoot-*; do
  [[ -f $secure_boot_variable ]] || continue
  if od -An -j4 -N1 -t u1 "$secure_boot_variable" 2>/dev/null | grep -Eq '(^|[[:space:]])1([[:space:]]|$)'; then
    printf '\e[31mDisable Secure Boot before installing Omyvoid.\e[0m\n' >&2
    exit 1
  fi
done

if [[ -z ${OMYVOID_ISO_BUILD:-} && -z ${OMYVOID_CHROOT_INSTALL:-} ]]; then
  root_fs=$(findmnt -n -o FSTYPE /)
  boot_fs=$(findmnt -n -o FSTYPE /boot 2>/dev/null || true)
  if [[ $boot_fs != "vfat" ]]; then
    boot_fs=$(findmnt -n -o FSTYPE /boot/efi 2>/dev/null || true)
  fi
  if [[ $root_fs != "btrfs" ]]; then
    printf '\e[31mOmyvoid requires Btrfs for /.\e[0m\n' >&2
    exit 1
  fi
  if [[ $boot_fs != "vfat" ]]; then
    printf '\e[31mOmyvoid requires a FAT32 partition mounted at /boot or /boot/efi.\e[0m\n' >&2
    exit 1
  fi
fi

source $OMYVOID_INSTALL/preflight/begin.sh

if [[ -n ${OMYVOID_ONLINE_INSTALL:-} ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: online preflight" >> "$OMYVOID_INSTALL_LOG_FILE"

  {
    sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree ca-certificates || true

    sudo install -d -m 0755 /etc/xbps.d
    if [[ ! -f /etc/xbps.d/00-repository-main.conf ]]; then
      sudo cp /usr/share/xbps.d/00-repository-main.conf /etc/xbps.d/00-repository-main.conf
    fi
    if ! grep -q '^repository=https://mirror.black-hole.dev/x86_64/' /etc/xbps.d/00-repository-main.conf; then
      sudo sed -i '1i repository=https://mirror.black-hole.dev/x86_64/' /etc/xbps.d/00-repository-main.conf
    fi

    omyvoid_repo=${OMYVOID_XBPS_REPOSITORY:-https://packages.omyvoid.org/current}
    if curl -sI -m 3 "$omyvoid_repo/x86_64-repodata" >/dev/null 2>&1; then
      printf 'repository=%s\n' "$omyvoid_repo" | sudo tee /etc/xbps.d/10-omyvoid.conf >/dev/null
    else
      sudo rm -f /etc/xbps.d/10-omyvoid.conf
    fi

    local_repo=""
    if [[ -d /opt/omyvoid/repository ]]; then
      local_repo="/opt/omyvoid/repository"
    elif [[ -d ${OMYVOID_PATH:-}/build/repository ]]; then
      local_repo="${OMYVOID_PATH}/build/repository"
    elif [[ -d ${OMYVOID_PATH:-}/repository ]]; then
      local_repo="${OMYVOID_PATH}/repository"
    fi

    if [[ -n $local_repo ]]; then
      printf 'repository=%s\n' "$local_repo" | sudo tee /etc/xbps.d/10-omyvoid-local.conf >/dev/null
    fi

    sudo xbps-install -S || true

    if ! xbps-query -R omyvoid-limine-entry-tool >/dev/null 2>&1; then
      echo "Building custom Omyvoid XBPS packages locally..."
      omyvoid_root="${OMYVOID_PATH:-$HOME/.local/share/omyvoid}"
      OMYVOID_XBPS_SIGNING_KEY='' "$omyvoid_root/release/build-xbps-repo.sh" "$omyvoid_root/build/repository"
      printf 'repository=%s/build/repository\n' "$omyvoid_root" | sudo tee /etc/xbps.d/10-omyvoid-local.conf >/dev/null
      sudo xbps-install -S
    fi
  } >> "$OMYVOID_INSTALL_LOG_FILE" 2>&1

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: online preflight" >> "$OMYVOID_INSTALL_LOG_FILE"
fi

run_logged $OMYVOID_INSTALL/preflight/show-env.sh
run_logged $OMYVOID_INSTALL/preflight/migrations.sh
run_logged $OMYVOID_INSTALL/preflight/first-run-mode.sh
