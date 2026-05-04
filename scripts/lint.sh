#!/usr/bin/env bash
#
# Lumen lint runner.
#
# Runs SwiftLint with the project's `.swiftlint.yml`, which enforces the
# design-system contract: no padding/frame/font/color/opacity/animation/sleep
# literals outside `Apple/lumen/Shared/DesignSystem/`.
#
# Usage:
#   ./scripts/lint.sh           # run, exit non-zero on any error
#   ./scripts/lint.sh --warn    # treat all violations as warnings (informational)
#
# To wire this into Xcode as a build-time guard, add a Run Script Build Phase
# to the `lumen` target with:
#     "${SRCROOT}/../scripts/lint.sh"
# Place it BEFORE the "Compile Sources" phase so a violation fails the build
# before the compiler runs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "warning: SwiftLint is not installed. Install it with:"
  echo "    brew install swiftlint"
  echo "Skipping lint check."
  exit 0
fi

case "${1:-}" in
  --warn)
    swiftlint --config "$REPO_ROOT/.swiftlint.yml"
    ;;
  *)
    swiftlint --strict --config "$REPO_ROOT/.swiftlint.yml"
    ;;
esac
