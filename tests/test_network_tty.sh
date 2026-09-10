#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# A network Optolink endpoint is passed to vcontrold, never awaited as a device file.
TEST_TTY=192.0.2.1:3000 timeout 5 bash "${repo_root}/tests/test_vcontrold_run.sh"
