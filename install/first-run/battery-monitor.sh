#!/bin/bash

set -euo pipefail

if omyvoid-battery-present; then
  powerprofilesctl set balanced || true
  service="$HOME/.config/service/omyvoid-battery"
  mkdir -p "$service"
  cat > "$service/run" <<'EOF'
#!/bin/sh
while :; do
  omyvoid-battery-monitor
  sleep 30
done
EOF
  chmod 0755 "$service/run"
  sv up "$service" 2>/dev/null || true
else
  powerprofilesctl set performance || true
fi
