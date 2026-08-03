sudo mkdir -p /etc/zzz.d/suspend
sudo install -m 0755 -o root -g root "$OMYVOID_PATH/default/zzz/unmount-fuse" /etc/zzz.d/suspend/50-omyvoid-unmount-fuse
