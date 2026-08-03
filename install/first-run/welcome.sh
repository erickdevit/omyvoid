source "${OMYVOID_PATH:-$HOME/.local/share/omyvoid}/default/i18n/init.sh"

omyvoid-notification-send -g "" "$I18N_FIRST_RUN_WELCOME_TITLE" "$I18N_FIRST_RUN_WELCOME_BODY" -u critical
