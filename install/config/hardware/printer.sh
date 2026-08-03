chrootable_runit_enable cupsd

chrootable_runit_enable avahi-daemon

# Enable mDNS resolution for .local domains
sudo sed -i 's/^hosts:.*/hosts: files mdns_minimal [NOTFOUND=return] dns/' /etc/nsswitch.conf

# Enable automatically adding remote printers
if ! grep -q '^CreateRemotePrinters Yes' /etc/cups/cups-browsed.conf; then
  echo 'CreateRemotePrinters Yes' | sudo tee -a /etc/cups/cups-browsed.conf
fi

chrootable_runit_enable cups-browsed
