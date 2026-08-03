FONT_DIR="/usr/local/share/fonts/truetype/omyvoid"
mkdir -p "$FONT_DIR"

# Omyvoid logo in a font for Waybar use
cp "$OMYVOID_PATH/config/omyvoid.ttf" "$FONT_DIR/"

fc-cache -f
