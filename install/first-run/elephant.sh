#!/bin/bash

set -euo pipefail

for definition in "elephant:elephant" "walker:walker --gapplication-service"; do
  name=${definition%%:*}
  process=${definition#*:}
  service="$HOME/.config/service/$name"
  mkdir -p "$service"
  printf '#!/bin/sh\nexec %s 2>&1\n' "$process" > "$service/run"
  chmod 0755 "$service/run"
  sv up "$service" 2>/dev/null || true
done
