if omyvoid-battery-present; then
  cat <<EOF | sudo tee "/etc/udev/rules.d/99-power-profile.rules"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="$OMYVOID_PATH/bin/omyvoid-powerprofiles-set"
SUBSYSTEM=="power_supply", ATTR{type}=="USB", RUN+="$OMYVOID_PATH/bin/omyvoid-powerprofiles-set"
EOF

  chrootable_runit_enable power-profiles-daemon

  sudo udevadm control --reload 2>/dev/null
  sudo udevadm trigger --subsystem-match=power_supply 2>/dev/null
fi
