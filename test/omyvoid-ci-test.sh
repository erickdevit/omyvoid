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
github_release="$root/.github/workflows/release.yml"
actionlint_config="$root/.github/actionlint.yaml"
gitlab_ci="$root/.gitlab-ci.yml"

echo '# GitHub Actions'
assert_contains 'pull request validation uses a GitHub-hosted runner' "$github_ci" 'runs-on: ubuntu-latest'
assert_contains 'pull request validation uses the official Void glibc container' "$github_ci" 'ghcr.io/void-linux/void-glibc-full:latest'
assert_contains 'package builds stay on the dedicated Void runner' "$github_ci" 'runs-on: \[self-hosted, void-linux, x86_64, omyvoid-builder\]'
assert_contains 'GitHub CI uses the shared validation entry point' "$github_ci" 'run: test/ci\.sh'
assert_contains 'GitHub release uses the shared validation entry point' "$github_release" 'run: test/ci\.sh'
assert_contains 'GitHub release uses the isolated privileged runner' "$github_release" 'runs-on: \[self-hosted, void-linux, x86_64, omyvoid-release\]'
assert_contains 'GitHub manual releases are restricted to promotion branches' "$github_release" "github\.ref == 'refs/heads/dev'"
assert_contains 'GitHub release removes materialized signing keys' "$github_release" 'Remove materialized signing keys'
assert_contains 'actionlint recognizes the package runner label' "$actionlint_config" 'omyvoid-builder'
assert_contains 'actionlint recognizes the release runner label' "$actionlint_config" 'omyvoid-release'

if grep -Eq 'uses: [^#[:space:]]+@v[0-9]' "$github_ci" "$github_release"; then
  nok 'third-party GitHub actions are pinned to immutable commits'
else
  ok 'third-party GitHub actions are pinned to immutable commits'
fi

echo '# GitLab CI/CD'
[[ -f $gitlab_ci ]] && ok 'GitLab pipeline definition exists' || nok 'GitLab pipeline definition exists'
assert_contains 'GitLab merge request validation uses the official Void image' "$gitlab_ci" 'image: ghcr.io/void-linux/void-glibc-full:latest'
assert_contains 'GitLab package jobs target the dedicated builder' "$gitlab_ci" 'omyvoid-builder'
assert_contains 'GitLab ISO jobs target the isolated release runner' "$gitlab_ci" 'omyvoid-release'
assert_contains 'GitLab development ISO is manual' "$gitlab_ci" '^iso:dev:'
assert_contains 'GitLab development ISO uses an approval environment' "$gitlab_ci" 'name: development'
assert_contains 'GitLab releases are restricted to version tags' "$gitlab_ci" 'CI_COMMIT_TAG =~ /\^v\[0-9\]'
assert_contains 'GitLab release publishes through the shared R2 script' "$gitlab_ci" 'release/publish-r2\.sh'
assert_contains 'GitLab release creates durable R2 asset links' "$gitlab_ci" 'glab release create'

echo '# Privilege boundary'
assert_contains 'top-level ISO build rejects root execution' "$root/install/iso/build-iso.sh" 'EUID != 0'
assert_contains 'only void-mklive is invoked through sudo' "$root/install/iso/build-iso.sh" 'sudo_args\[@\].*mklive\.sh'
assert_contains 'CI requires non-interactive sudo' "$root/install/iso/build-iso.sh" 'sudo -n true'

(( failures == 0 )) || exit 1
