#!/usr/bin/env bash
# Active Reduce Motion sur le simulator pour tester la compliance a11y
set -euo pipefail
# iOS 17+ : settings.plist patch via simctl
xcrun simctl spawn booted defaults write com.apple.Accessibility ReduceMotionAutoplayVideosEnabled 0
xcrun simctl spawn booted defaults write com.apple.Accessibility ReduceMotionEnabled 1
xcrun simctl ui booted appearance --reduce-motion on 2>/dev/null || true
