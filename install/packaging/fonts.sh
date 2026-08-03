FONT_DIR="/usr/local/share/fonts/truetype/omyvoid"
mkdir -p "$FONT_DIR"

# Canonical Omyvoid mark at U+E900 for Waybar, Walker and terminal fallbacks.
install -m 0644 "$OMYVOID_PATH/default/fonts/OmyvoidIcons.ttf" \
  "$FONT_DIR/OmyvoidIcons.ttf"

fc-cache -f
