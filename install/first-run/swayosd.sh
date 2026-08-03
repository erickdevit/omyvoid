#!/bin/bash

set -euo pipefail

service="$HOME/.config/service/swayosd"
mkdir -p "$service"
cat > "$service/run" <<'EOF'
#!/bin/sh
exec swayosd-server 2>&1
EOF
chmod 0755 "$service/run"
sv up "$service" 2>/dev/null || true
