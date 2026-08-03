#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
failures=0

ok() {
  echo "ok - $1"
}

nok() {
  echo "not ok - $1" >&2
  failures=$((failures + 1))
}

assert_contains() {
  local description="$1"
  local file="$2"
  local pattern="$3"

  grep -Eq "$pattern" "$file" && ok "$description" || nok "$description"
}

github_ci="$root/.github/workflows/ci.yml"
gitlab_ci="$root/.gitlab-ci.yml"

echo '# GitHub Actions'
assert_contains 'pull request validation uses a GitHub-hosted runner' "$github_ci" 'runs-on: ubuntu-latest'
assert_contains 'pull request validation uses the official Void glibc container' "$github_ci" 'ghcr.io/void-linux/void-glibc-full:latest'
assert_contains 'GitHub CI uses the shared validation entry point' "$github_ci" 'run: test/ci\.sh'

if grep -Eq 'uses: [^#[:space:]]+@v[0-9]' "$github_ci"; then
  nok 'third-party GitHub actions are pinned to immutable commits'
else
  ok 'third-party GitHub actions are pinned to immutable commits'
fi

echo '# GitLab CI/CD'
[[ -f $gitlab_ci ]] && ok 'GitLab pipeline definition exists' || nok 'GitLab pipeline definition exists'
assert_contains 'GitLab merge request validation uses the official Void image' "$gitlab_ci" 'ghcr.io/void-linux/void-glibc-full:latest'

echo '# Privilege boundary'
assert_contains 'top-level ISO build rejects root execution' "$root/install/iso/build-iso.sh" 'EUID != 0'
assert_contains 'only void-mklive is invoked through sudo' "$root/install/iso/build-iso.sh" 'sudo_args\[@\].*mklive\.sh'
assert_contains 'CI requires non-interactive sudo' "$root/install/iso/build-iso.sh" 'sudo -n true'

(( failures == 0 )) || exit 1
