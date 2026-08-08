#!/usr/bin/env bash
# Format + analyze. Run before every commit.
set -e
cd "$(dirname "$0")/.."

# ponytail: PATH fallback because the Flutter SDK is not always exported
command -v flutter >/dev/null || export PATH="$HOME/flutter/bin:$PATH"

dart format lib $([ -d test ] && echo test)
flutter analyze
