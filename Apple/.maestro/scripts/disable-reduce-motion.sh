#!/usr/bin/env bash
# Désactive Reduce Motion (cleanup post-test a11y)
set -euo pipefail
xcrun simctl spawn booted defaults write com.apple.Accessibility ReduceMotionEnabled 0
xcrun simctl ui booted appearance --reduce-motion off 2>/dev/null || true
