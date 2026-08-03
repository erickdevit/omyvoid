# Copy all bundled icons to the applications/icons directory
ICON_DIR="$HOME/.local/share/applications/icons"
mkdir -p "$ICON_DIR"
cp "$OMYVOID_PATH"/applications/icons/*.png "$ICON_DIR/"

# Copy system-wide cursor themes
if [[ -d "$OMYVOID_PATH/default/icons" ]]; then
  sudo mkdir -p /usr/share/icons
  sudo cp -a "$OMYVOID_PATH/default/icons/volantes_cursors" /usr/share/icons/
  sudo cp -a "$OMYVOID_PATH/default/icons/volantes_light_cursors" /usr/share/icons/
fi
