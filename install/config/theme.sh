# Setup user theme folder
mkdir -p ~/.config/omyvoid/themes

# Chromium policy directory for theme
sudo mkdir -p /etc/chromium/policies/managed
sudo chmod a+rw /etc/chromium/policies/managed

# Set initial theme
omyvoid-theme-set "Omyvoid"
rm -rf ~/.config/chromium/SingletonLock

# Set specific app links for current theme
mkdir -p ~/.config/btop/themes
ln -snf ../../omyvoid/current/theme/btop.theme ~/.config/btop/themes/current.theme

mkdir -p ~/.config/mako
ln -snf ../omyvoid/current/theme/mako.ini ~/.config/mako/config

mkdir -p ~/.config/cava
ln -snf ../omyvoid/current/theme/cava.ini ~/.config/cava/config

# Default Chromium to follow system appearance ("device") instead of dark
sudo mkdir -p /usr/lib/chromium
echo '{"browser":{"theme":{"color_scheme":0,"color_scheme2":0}}}' | sudo tee /usr/lib/chromium/initial_preferences >/dev/null
