#!/bin/sh

snapshot_id=$(getarg omyvoid.snapshot=)
[ -n "$snapshot_id" ] && [ -d /sysroot ] || exit 0

mkdir -p /run/omyvoid-snapshot
mount -t tmpfs -o mode=0755 tmpfs /run/omyvoid-snapshot
mkdir -p /run/omyvoid-snapshot/lower /run/omyvoid-snapshot/upper /run/omyvoid-snapshot/work
mount --move /sysroot /run/omyvoid-snapshot/lower
mkdir -p /sysroot
mount -t overlay overlay \
  -o lowerdir=/run/omyvoid-snapshot/lower,upperdir=/run/omyvoid-snapshot/upper,workdir=/run/omyvoid-snapshot/work \
  /sysroot
