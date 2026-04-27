#!/usr/bin/env bash
# qa_install.sh — boot iPhone simulator, build Lumen, install + launch the app.
# Outputs UDID + bundle ID to stdout in `key=value` format for downstream parsing.
#
# Usage:
#   ./scripts/qa_install.sh                    # iPhone 17 Pro (default)
#   SIM_NAME="iPhone 17 Pro Max" ./scripts/qa_install.sh
#
# Required env / state:
#   - Apple/lumen.xcodeproj exists at the cwd-relative path
#   - Apple/lumen/Config/Secrets.xcconfig exists (gitignored locally)
#   - Xcode + simulator installed
#
# Stops on first error. Idempotent: re-running re-installs latest build.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="${REPO_ROOT}/Apple/lumen.xcodeproj"
SCHEME="lumen"
BUNDLE_ID="com.highthem.lumen"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
CONFIG="${CONFIG:-Debug}"

echo "==> Locating simulator: ${SIM_NAME}"
UDID="$(xcrun simctl list devices available | grep -E "${SIM_NAME} \(" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' || true)"
if [[ -z "${UDID}" ]]; then
  echo "ERROR: simulator '${SIM_NAME}' not found. Available:"
  xcrun simctl list devices available | grep iPhone
  exit 1
fi
echo "    UDID=${UDID}"

echo "==> Booting simulator (idempotent)"
xcrun simctl bootstatus "${UDID}" -b >/dev/null 2>&1 || xcrun simctl boot "${UDID}"
xcrun simctl bootstatus "${UDID}" -b >/dev/null

echo "==> Opening Simulator.app (so QA agent can interact)"
open -a Simulator --args -CurrentDeviceUDID "${UDID}" || true

echo "==> Building Lumen (configuration: ${CONFIG})"
DERIVED="$(mktemp -d /tmp/lumen-qa-derived.XXXXXX)"
xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIG}" \
  -destination "platform=iOS Simulator,id=${UDID}" \
  -derivedDataPath "${DERIVED}" \
  build \
  >"${DERIVED}/build.log" 2>&1
echo "    build log: ${DERIVED}/build.log"

APP_PATH="${DERIVED}/Build/Products/${CONFIG}-iphonesimulator/lumen.app"
if [[ ! -d "${APP_PATH}" ]]; then
  echo "ERROR: built app not found at ${APP_PATH}"
  tail -40 "${DERIVED}/build.log"
  exit 1
fi
echo "    app path: ${APP_PATH}"

echo "==> Uninstalling previous instance (if any)"
xcrun simctl uninstall "${UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true

echo "==> Installing app"
xcrun simctl install "${UDID}" "${APP_PATH}"

echo "==> Launching app"
xcrun simctl launch "${UDID}" "${BUNDLE_ID}" >/dev/null

echo
echo "=== READY FOR QA ==="
echo "udid=${UDID}"
echo "sim_name=${SIM_NAME}"
echo "bundle_id=${BUNDLE_ID}"
echo "app_path=${APP_PATH}"
echo "build_log=${DERIVED}/build.log"
