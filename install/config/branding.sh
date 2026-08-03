# Allow the user to change the branding for fastfetch and screensaver
mkdir -p ~/.config/omyvoid/branding
cp "$OMYVOID_PATH"/icon.txt ~/.config/omyvoid/branding/about.txt
cp "$OMYVOID_PATH"/logo.txt ~/.config/omyvoid/branding/screensaver.txt

# Install the Omyvoid-only U+E900 icon used by Waybar, Walker and Ghostty.
font_dir="$HOME/.local/share/fonts/omyvoid"
mkdir -p "$font_dir"
install -m 0644 "$OMYVOID_PATH/default/fonts/OmyvoidIcons.ttf" \
  "$font_dir/OmyvoidIcons.ttf"
fc-cache -f "$font_dir" >/dev/null 2>&1 || true
