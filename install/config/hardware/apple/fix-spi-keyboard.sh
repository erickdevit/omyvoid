# Detect MacBook models that need SPI keyboard modules
product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
if [[ $product_name =~ MacBook[89],1|MacBook1[02],1|MacBookPro13,[123]|MacBookPro14,[123] ]]; then
  echo "Detected MacBook with SPI keyboard"

  omyvoid-pkg-add macbook12-spi-driver-dkms
  # Add modules to the dracut image.
  if [[ $product_name == "MacBook8,1" ]]; then
    mods=(applespi spi_pxa2xx_platform spi_pxa2xx_pci)
  else
    mods=(applespi intel_lpss_pci spi_pxa2xx_platform)
  fi
  printf 'add_drivers+=" %s "\n' "${mods[*]}" | sudo tee /etc/dracut.conf.d/56-omyvoid-apple-spi.conf >/dev/null
fi
