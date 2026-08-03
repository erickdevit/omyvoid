# Overwrite parts of the omyvoid-menu with user-specific submenus.
# See $OMYVOID_PATH/bin/omyvoid-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when Omyvoid changes.
#
# Example of minimal system menu:
#
# show_system_menu() {
#   case $(menu "System" "  Lock\n󰐥  Shutdown") in
#   *Lock*) omyvoid-system-lock ;;
#   *Shutdown*) omyvoid-system-shutdown ;;
#   *) back_to show_main_menu ;;
#   esac
# }
#
# Example of overriding just the about menu action: (Using zsh instead of bash (default))
#
# show_about() {
#   exec omyvoid-launch-or-focus-tui "zsh -c 'fastfetch; read -k 1'"
# }
