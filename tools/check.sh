#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

flutter pub get
dart format --output=none --set-exit-if-changed \
  lib test integration_test test_driver
flutter analyze
flutter test
