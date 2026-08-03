# NetworkManager uses iwd as its Wi-Fi backend and is supervised by runit.
sudo mkdir -p /etc/NetworkManager/conf.d
cat <<EOF | sudo tee /etc/NetworkManager/conf.d/10-omyvoid-wifi.conf >/dev/null
[device]
wifi.backend=iwd
EOF

chrootable_runit_enable dbus
chrootable_runit_enable NetworkManager
