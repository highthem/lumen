#!/usr/bin/env bash
# Build, install, and run Lumen Maestro flows on a booted iOS Simulator.
#
# Usage:
#   ./scripts/test_maestro.sh
#   TAGS=smoke ./scripts/test_maestro.sh
#   FLOW=Apple/.maestro/flows/smoke/01-app-launch.yaml ./scripts/test_maestro.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

FLOW="${FLOW:-Apple/.maestro}"
TAGS="${TAGS:-}"
EXCLUDE_TAGS="${EXCLUDE_TAGS:-}"
REPORT_DIR="${REPORT_DIR:-${REPO_ROOT}/build/maestro}"
CONFIG_FILE="${CONFIG_FILE:-${REPO_ROOT}/Apple/.maestro/config.yaml}"

mkdir -p "${REPORT_DIR}/debug" "${REPORT_DIR}/results"

echo "==> Building and installing Lumen"
INSTALL_OUTPUT="$("${REPO_ROOT}/scripts/qa_install.sh")"
printf '%s\n' "${INSTALL_OUTPUT}"

UDID="$(printf '%s\n' "${INSTALL_OUTPUT}" | awk -F= '/^udid=/{print $2; exit}')"

MAESTRO_ARGS=(
  test
  --config "${CONFIG_FILE}"
  --format JUNIT
  --output "${REPORT_DIR}/maestro-report.xml"
  --test-output-dir "${REPORT_DIR}/results"
  --debug-output "${REPORT_DIR}/debug"
)

if [[ -n "${UDID}" ]]; then
  MAESTRO_ARGS+=(--udid "${UDID}")
fi

if [[ -n "${TAGS}" ]]; then
  MAESTRO_ARGS+=(--include-tags "${TAGS}")
fi

if [[ -n "${EXCLUDE_TAGS}" ]]; then
  MAESTRO_ARGS+=(--exclude-tags "${EXCLUDE_TAGS}")
fi

MAESTRO_ARGS+=("${FLOW}")

echo "==> Running Maestro"
echo "    report: ${REPORT_DIR}/maestro-report.xml"
echo "    artifacts: ${REPORT_DIR}/results"
echo "    debug: ${REPORT_DIR}/debug"
maestro "${MAESTRO_ARGS[@]}"

