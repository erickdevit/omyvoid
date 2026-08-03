# Fix NVMe suspend issues on MacBook models
# This prevents NVMe drives from failing to wake from sleep properly
MACBOOK_MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)

if [[ $MACBOOK_MODEL =~ MacBook(8,1|9,1|10,1)|MacBookPro13,[123]|MacBookPro14,[123] ]]; then
  echo "Detected MacBook model: $MACBOOK_MODEL"

  NVME_DEVICE="/sys/bus/pci/devices/0000:01:00.0/d3cold_allowed"

  if [[ -f $NVME_DEVICE ]]; then
    echo "Applying NVMe suspend fix..."

    cat <<EOF | sudo tee /etc/udev/rules.d/99-omyvoid-macbook-nvme.rules >/dev/null
ACTION=="add", SUBSYSTEM=="pci", KERNELS=="0000:01:00.0", ATTR{d3cold_allowed}="0"
EOF
    echo 0 | sudo tee "$NVME_DEVICE" >/dev/null
  else
    echo "Warning: NVMe device not found at expected PCI address (0000:01:00.0)"
    echo "This fix may not be needed for this MacBook model"
  fi
fi
