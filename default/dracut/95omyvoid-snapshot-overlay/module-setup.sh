#!/bin/bash

check() {
  return 0
}
depends() {
  echo btrfs
}

install() {
  inst_multiple awk grep mkdir mount mv
  inst_hook pre-pivot 90 "$moddir/omyvoid-snapshot-overlay.sh"
}
