# Install all base packages
mapfile -t packages < <(grep -v '^#' "$OMYVOID_INSTALL/omyvoid-base.packages" | grep -v '^$')
omyvoid-pkg-add "${packages[@]}"
