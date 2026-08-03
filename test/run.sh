#!/bin/bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

"$ROOT/test/omyvoid-iso-test.sh"
"$ROOT/test/omyvoid-cli-test.sh"
"$ROOT/test/omyvoid-update-available-test.sh"
