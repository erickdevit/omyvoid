#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define Omyvoid locations
export OMYVOID_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMYVOID_INSTALL="$OMYVOID_PATH/install"
export OMYVOID_INSTALL_LOG_FILE="/var/log/omyvoid-install.log"
export PATH="$OMYVOID_PATH/bin:$PATH"

# Sourced helpers (loads gum and logo functions)
source "$OMYVOID_INSTALL/helpers/all.sh"

# Select language (skip in ISO/chroot builds)
clear_logo
if [[ -n ${OMYVOID_ISO_BUILD:-} || -n ${OMYVOID_CHROOT_INSTALL:-} ]]; then
  LANG_VAL="en"
else
  echo -e "\n${PADDING_LEFT_SPACES}Choose Omyvoid language / Selecione o idioma / Seleccione el idioma:"
  CHOSEN_LANG=$(gum choose --height 5 "English" "Português (Brasil)" "Español")

  case "$CHOSEN_LANG" in
    "Português (Brasil)") LANG_VAL="pt-br" ;;
    "Español") LANG_VAL="es" ;;
    *) LANG_VAL="en" ;;
  esac
fi

mkdir -p "$HOME/.config/omyvoid"
echo "$LANG_VAL" > "$HOME/.config/omyvoid/language"
export OMYVOID_LANGUAGE="$LANG_VAL"

# Load translation variables
source "$OMYVOID_PATH/default/i18n/init.sh"

# Install
source "$OMYVOID_INSTALL/preflight/all.sh"
source "$OMYVOID_INSTALL/packaging/all.sh"
source "$OMYVOID_INSTALL/config/all.sh"
source "$OMYVOID_INSTALL/login/all.sh"
source "$OMYVOID_INSTALL/post-install/all.sh"
