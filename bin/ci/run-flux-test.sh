#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/step-summary.sh"

./bin/tests/flux-d2/test.sh

write_step_summary "Flux D2 bootstrap test completed successfully"
