# Copy over Omyvoid configs
mkdir -p ~/.config
cp -R "$OMYVOID_PATH"/config/* ~/.config/
mkdir -p ~/.config/omyvoid/branding

# Use default bashrc from Omyvoid
cp "$OMYVOID_PATH"/default/bashrc ~/.bashrc
