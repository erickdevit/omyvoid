#!/bin/bash

# Ensure Walker service is started automatically on boot
mkdir -p ~/.config/autostart/
cp $OMYVOID_PATH/default/walker/walker.desktop ~/.config/autostart/

# Link the visual theme menu config
mkdir -p ~/.config/elephant/menus
ln -snf $OMYVOID_PATH/default/elephant/omyvoid_themes.lua ~/.config/elephant/menus/omyvoid_themes.lua
ln -snf $OMYVOID_PATH/default/elephant/omyvoid_background_selector.lua ~/.config/elephant/menus/omyvoid_background_selector.lua
ln -snf $OMYVOID_PATH/default/elephant/omyvoid_unlocks.lua ~/.config/elephant/menus/omyvoid_unlocks.lua
