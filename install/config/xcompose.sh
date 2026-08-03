# Set default XCompose that is triggered with CapsLock
tee ~/.XCompose >/dev/null <<EOF
# Run omyvoid-restart-xcompose to apply changes

# Include fast emoji access
include "$OMYVOID_PATH/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$OMYVOID_USER_NAME"
<Multi_key> <space> <e> : "$OMYVOID_USER_EMAIL"
EOF
