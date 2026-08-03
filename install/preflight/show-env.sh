# Show installation environment variables
gum log --level info "Installation Environment:"

env | grep -E "^(OMYVOID_CHROOT_INSTALL|OMYVOID_ONLINE_INSTALL|OMYVOID_USER_NAME|OMYVOID_USER_EMAIL|USER|HOME|OMYVOID_REPO|OMYVOID_REF|OMYVOID_PATH)=" | sort | while IFS= read -r var; do
  gum log --level info "  $var"
done
