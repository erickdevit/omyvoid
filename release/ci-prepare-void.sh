#!/bin/bash

set -euo pipefail

profile=${1:-test}
packages=(bash cargo curl git jq python3 python3-yaml ripgrep shellcheck xtools)
required_commands=(bash cargo curl git jq python3 rg shellcheck xbps-query xlint)
required_packages=()
install_dependencies=false

case "$profile" in
  test)
    install_dependencies=true
    ;;
  packages)
    required_commands+=(xbps-rindex)
    required_packages+=(base-devel)
    ;;
  builder)
    required_commands+=(
      gh
      glab
      mcopy
      mformat
      minisign
      rclone
      rsync
      sudo
      xbps-install
      xbps-rindex
      xorriso
    )
    required_packages+=(
      base-devel
      limine
    )
    ;;
  *)
    echo "Usage: ci-prepare-void.sh <test|packages|builder>" >&2
    exit 2
    ;;
esac

[[ -f /etc/os-release ]] && grep -q '^ID=void$' /etc/os-release || {
  echo "The CI runner must use Void Linux" >&2
  exit 1
}
[[ $(uname -m) == "x86_64" ]] || {
  echo "The CI runner must use x86_64" >&2
  exit 1
}
getconf GNU_LIBC_VERSION >/dev/null 2>&1 || {
  echo "The CI runner must use glibc" >&2
  exit 1
}

if [[ $install_dependencies == true ]]; then
  xbps=(xbps-install)
  if (( EUID != 0 )); then
    command -v sudo >/dev/null || {
      echo "A non-root validation runner requires sudo" >&2
      exit 1
    }
    sudo -n true || {
      echo "The validation runner requires non-interactive sudo for setup" >&2
      exit 1
    }
    xbps=(sudo -n xbps-install)
  fi

  "${xbps[@]}" -Syu xbps
  "${xbps[@]}" -Sy "${packages[@]}"
fi

for command in "${required_commands[@]}"; do
  command -v "$command" >/dev/null || {
    echo "Missing dependency for the $profile profile: $command" >&2
    exit 1
  }
done

for package in "${required_packages[@]}"; do
  xbps-query "$package" >/dev/null || {
    echo "Missing package for the $profile profile: $package" >&2
    exit 1
  }
done

if [[ $profile == "builder" && ! -f /usr/share/limine/BOOTX64.EFI ]]; then
  echo "The builder profile requires /usr/share/limine/BOOTX64.EFI" >&2
  exit 1
fi

if [[ $profile == "builder" ]] && (( EUID != 0 )); then
  sudo -n true || {
    echo "The ISO builder requires non-interactive sudo for void-mklive" >&2
    exit 1
  }
fi
