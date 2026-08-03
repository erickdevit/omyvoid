#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export OMYVOID_ONLINE_INSTALL=true

ansi_art=' ▄██████▄    ▄▄▄▄███▄▄▄▄   ▄██   ▄    ▄█    █▄   ▄██████▄   ▄█  ████████▄
███    ███ ▄██▀▀▀███▀▀▀██▄ ███   ██▄ ███    ███ ███    ███ ███  ███   ▀███
███    ███ ███   ███   ███ ███▄▄▄███ ███    ███ ███    ███ ███▌ ███    ███
███    ███ ███   ███   ███ ▀▀▀▀▀▀███ ███    ███ ███    ███ ███▌ ███    ███
███    ███ ███   ███   ███ ▄██   ███ ███    ███ ███    ███ ███▌ ███    ███
███    ███ ███   ███   ███ ███   ███ ███    ███ ███    ███ ███  ███    ███
███    ███ ███   ███   ███ ███   ███ ███    ███ ███    ███ ███  ███   ▄███
 ▀██████▀   ▀█   ███   █▀   ▀█████▀   ▀██████▀   ▀██████▀  █▀   ████████▀'

clear
echo -e "\n$ansi_art\n"

# Use a custom branch if instructed, otherwise default to the stable branch.
OMYVOID_REF="${OMYVOID_REF:-main}"

if [[ $OMYVOID_REF == "dev" ]]; then
  echo -e "\e[33mDev branch selected\e[0m"
elif [[ $OMYVOID_REF == "rc" ]]; then
  echo -e "\e[33mRC branch selected\e[0m"
else
  echo -e "\e[32mStable branch selected\e[0m"
fi

if [[ ! -f /etc/os-release ]] || ! grep -Eq '^ID=void$' /etc/os-release; then
  echo "Omyvoid requires a clean Void Linux x86_64-glibc installation." >&2
  exit 1
fi

sudo xbps-install -Sy git curl sudo bash

# Use custom repo if specified, otherwise default to erickdevit/omyvoid
OMYVOID_REPO="${OMYVOID_REPO:-erickdevit/omyvoid}"

echo -e "\nCloning Omyvoid from: https://github.com/${OMYVOID_REPO}.git"
if [[ -e $HOME/.local/share/omyvoid ]]; then
  mv "$HOME/.local/share/omyvoid" "$HOME/.local/share/omyvoid.backup.$(date +%Y%m%d%H%M%S)"
fi
git clone "https://github.com/${OMYVOID_REPO}.git" ~/.local/share/omyvoid >/dev/null

echo -e "\e[32mUsing branch: $OMYVOID_REF\e[0m"
cd ~/.local/share/omyvoid
git fetch origin "${OMYVOID_REF}" && git checkout "${OMYVOID_REF}"
cd -

echo -e "\nInstallation starting..."
source ~/.local/share/omyvoid/install.sh
