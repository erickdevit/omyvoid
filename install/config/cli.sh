#!/bin/bash

set -euo pipefail

# Keep /opt/omyvoid as the source of truth while exposing public commands in PATH.
sudo install -d -m 0755 /usr/local/bin
mkdir -p "$HOME/.local/share"
if [[ $(readlink -f "$OMYVOID_PATH") != $(readlink -f "$HOME/.local/share/omyvoid" 2>/dev/null || true) ]]; then
  ln -snf "$OMYVOID_PATH" "$HOME/.local/share/omyvoid"
fi
for command in "$OMYVOID_PATH"/bin/omyvoid*; do
  [[ -f $command && -x $command ]] || continue
  sudo ln -snf "$command" "/usr/local/bin/${command##*/}"
done
