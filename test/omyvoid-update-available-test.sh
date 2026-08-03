#!/bin/bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_ROOT=$(mktemp -d)
REMOTE_REPO="$TMP_ROOT/remote.git"
SOURCE_REPO="$TMP_ROOT/source"
INSTALL_REPO="$TMP_ROOT/install"
TEST_BIN="$TMP_ROOT/bin"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() { printf 'ok - %s\n' "$1"; }
fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }

git init --bare --quiet "$REMOTE_REPO"
git clone --quiet "$REMOTE_REPO" "$SOURCE_REPO"
git -C "$SOURCE_REPO" config user.name "Omyvoid Tests"
git -C "$SOURCE_REPO" config user.email "tests@omyvoid.invalid"
git -C "$SOURCE_REPO" switch --quiet -c dev

printf 'current dev\n' > "$SOURCE_REPO/state"
git -C "$SOURCE_REPO" add state
git -C "$SOURCE_REPO" commit --quiet -m 'current dev release'
git -C "$SOURCE_REPO" tag -a v0.1.0-dev.1 -m 'current dev tag'

git -C "$SOURCE_REPO" switch --quiet --orphan unrelated
git -C "$SOURCE_REPO" rm --quiet -rf . 2>/dev/null || true
printf 'unrelated\n' > "$SOURCE_REPO/state"
git -C "$SOURCE_REPO" add state
git -C "$SOURCE_REPO" commit --quiet -m 'unrelated release line'
git -C "$SOURCE_REPO" tag -a v9.0.0-dev.1 -m 'unrelated dev tag'

git -C "$SOURCE_REPO" push --quiet origin dev unrelated --tags
git clone --quiet --branch dev "$REMOTE_REPO" "$INSTALL_REPO"
mkdir -p "$TEST_BIN"
printf '#!/bin/bash\necho dev\n' > "$TEST_BIN/omyvoid-version-channel"
chmod +x "$TEST_BIN/omyvoid-version-channel"

set +e
output=$(PATH="$TEST_BIN:$PATH" OMYVOID_PATH="$INSTALL_REPO" "$ROOT/bin/omyvoid-update-available")
status=$?
set -e
(( status == 1 )) || fail 'up-to-date check returns status 1'
[[ $output == *'up to date (v0.1.0-dev.1)'* ]] || fail 'current dev tag is recognized'
pass 'current dev tag is recognized'

git -C "$SOURCE_REPO" switch --quiet dev
printf 'next dev\n' > "$SOURCE_REPO/state"
git -C "$SOURCE_REPO" commit --quiet -am 'publish next dev release'
git -C "$SOURCE_REPO" tag -a v0.1.0-dev.2 -m 'next dev tag'
git -C "$SOURCE_REPO" push --quiet origin dev --tags

output=$(PATH="$TEST_BIN:$PATH" OMYVOID_PATH="$INSTALL_REPO" "$ROOT/bin/omyvoid-update-available") || fail 'reachable tag reports an update'
[[ $output == *'update available (v0.1.0-dev.2)'* ]] || fail 'newest reachable dev tag is selected'
[[ $output != *v9.0.0-dev.1* ]] || fail 'unrelated tag is ignored'
pass 'newest reachable channel tag is selected and unrelated tags are ignored'
