if lspci | grep -qi 'nvidia'; then
  if omyvoid-hw-nvidia-gsp; then
    PACKAGES=(nvidia nvidia-libs)
    GPU_ARCH="turing_plus"
  elif omyvoid-hw-nvidia-without-gsp; then
    PACKAGES=(nvidia470 nvidia470-libs)
    GPU_ARCH="maxwell_pascal_volta"
  fi

  # Bail if no supported GPU
  if [[ -z ${PACKAGES+x} ]]; then
    echo "No compatible driver for your NVIDIA GPU."
    return 0 2>/dev/null || exit 0
  fi

  omyvoid-pkg-add "${PACKAGES[@]}"

  # Configure modprobe for early KMS
  sudo tee /etc/modprobe.d/nvidia.conf <<EOF > /dev/null
options nvidia_drm modeset=1
EOF

  sudo tee /etc/dracut.conf.d/50-omyvoid-nvidia.conf >/dev/null <<'EOF'
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOF

  # Add NVIDIA environment variables based on GPU architecture
  if [[ $GPU_ARCH = "turing_plus" ]]; then
    # Turing+ (RTX 20xx, GTX 16xx, and newer) with GSP firmware support
    cat >>"$HOME/.config/hypr/envs.lua" <<'EOF'

-- NVIDIA (Turing+ with GSP firmware)
hl.env("NVD_BACKEND", "direct")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
EOF
  elif [[ $GPU_ARCH = "maxwell_pascal_volta" ]]; then
    # Maxwell/Pascal/Volta — lack GSP firmware
    cat >>"$HOME/.config/hypr/envs.lua" <<'EOF'

-- NVIDIA (Maxwell/Pascal/Volta without GSP firmware)
hl.env("NVD_BACKEND", "egl")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
EOF
  fi
fi
