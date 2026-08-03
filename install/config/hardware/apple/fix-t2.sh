# Detect T2 MacBook models using PCI IDs
# Vendor: 106b (Apple), Device IDs: 1801 or 1802 (T2 Security Chip)
if lspci -nn | grep -q "106b:180[12]"; then
  echo "Detected MacBook with T2 chip. Installing support items..."

  omyvoid-pkg-add \
    linux-t2 \
    linux-t2-headers \
    apple-t2-audio-config \
    apple-bcm-firmware \
    t2fanrd \
    tiny-dfr

  # Add user to video group (required for tiny-dfr to access /dev/dri devices)
  sudo usermod -aG video ${USER}

  # Enable T2 services
  [[ -d /etc/sv/t2fanrd ]] && chrootable_runit_enable t2fanrd
  [[ -d /etc/sv/tiny-dfr ]] && chrootable_runit_enable tiny-dfr

  echo "apple-bce" | sudo tee /etc/modules-load.d/t2.conf >/dev/null
  echo "hci_bcm4377" | sudo tee -a /etc/modules-load.d/t2.conf >/dev/null

  sudo tee /etc/dracut.conf.d/55-omyvoid-t2.conf >/dev/null <<'EOF'
add_drivers+=" apple-bce usbhid hid_apple hid_generic xhci_pci xhci_hcd "
EOF

  cat <<EOF | sudo tee /etc/modprobe.d/brcmfmac.conf >/dev/null
# Fix for T2 MacBook WiFi connectivity issues
options brcmfmac feature_disable=0x82000
EOF

  sudo omyvoid-boot-cmdline-add intel_iommu=on iommu=pt pcie_ports=compat

  cat <<EOF | sudo tee /etc/t2fand.conf >/dev/null
[Fan1]
low_temp=55
high_temp=75
speed_curve=linear
always_full_speed=false
EOF
fi
