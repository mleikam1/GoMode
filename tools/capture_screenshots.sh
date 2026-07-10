#!/usr/bin/env bash
set -euo pipefail

device="${1:-emulator-5554}"

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_screenshot_test.dart \
  -d "$device"
