# Install Panther Lake kernel support for Dell XPS Panther Lake systems.
if omyvoid-hw-match "XPS" && omyvoid-hw-intel-ptl; then
  echo "Detected Dell XPS Panther Lake, installing OEM kernel..."

  omyvoid-pkg-add linux-oem-24.04
fi
