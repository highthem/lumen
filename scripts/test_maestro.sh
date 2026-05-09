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

run_single_flow() {
  local flow_path="$1"
  local slug
  slug="$(basename "${flow_path}" .yaml)"

  local args=("${MAESTRO_ARGS[@]}")
  args+=(--output "${REPORT_DIR}/reports/${slug}.xml")
  args+=(--test-output-dir "${REPORT_DIR}/results/${slug}")
  args+=(--debug-output "${REPORT_DIR}/debug/${slug}")
  args+=("${flow_path}")

  echo "==> Running Maestro flow: ${flow_path}"
  maestro "${args[@]}"
}

has_tag() {
  local flow_path="$1"
  local tag="$2"
  awk -v tag="${tag}" '
    /^tags:[[:space:]]*\[/ {
      line = $0
      gsub(/[\[\],]/, " ", line)
      n = split(line, parts, /[[:space:]]+/)
      for (i = 1; i <= n; i++) if (parts[i] == tag) found = 1
    }
    /^tags:[[:space:]]*$/ { in_tags = 1; next }
    in_tags && /^[^[:space:]-]/ { in_tags = 0 }
    in_tags && /^[[:space:]]*-[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/[[:space:]]+$/, "", line)
      if (line == tag) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "${flow_path}"
}

matches_tag_filters() {
  local flow_path="$1"
  local tag

  if [[ -n "${TAGS}" ]]; then
    local include_match=1
    IFS=',' read -ra include_tags <<< "${TAGS}"
    for tag in "${include_tags[@]}"; do
      tag="${tag//[[:space:]]/}"
      [[ -z "${tag}" ]] && continue
      if has_tag "${flow_path}" "${tag}"; then
        include_match=0
        break
      fi
    done
    [[ "${include_match}" -eq 0 ]] || return 1
  fi

  if [[ -n "${EXCLUDE_TAGS}" ]]; then
    IFS=',' read -ra exclude_tags <<< "${EXCLUDE_TAGS}"
    for tag in "${exclude_tags[@]}"; do
      tag="${tag//[[:space:]]/}"
      [[ -z "${tag}" ]] && continue
      if has_tag "${flow_path}" "${tag}"; then
        return 1
      fi
    done
  fi

  return 0
}

echo "==> Running Maestro"
echo "    reports: ${REPORT_DIR}/reports"
echo "    artifacts: ${REPORT_DIR}/results"
echo "    debug: ${REPORT_DIR}/debug"

if [[ "${FLOW}" != "Apple/.maestro" && "${FLOW}" != "${REPO_ROOT}/Apple/.maestro" ]]; then
  MAESTRO_ARGS+=(
    --output "${REPORT_DIR}/maestro-report.xml"
    --test-output-dir "${REPORT_DIR}/results"
    --debug-output "${REPORT_DIR}/debug"
    "${FLOW}"
  )
  maestro "${MAESTRO_ARGS[@]}"
  exit $?
fi

mkdir -p "${REPORT_DIR}/reports"

FLOW_FILES=()
while IFS= read -r flow_file; do
  FLOW_FILES+=("${flow_file}")
done < <(find "${REPO_ROOT}/Apple/.maestro/flows" -type f -name '*.yaml' ! -path '*/_shared/*' | sort)

FAILED=()
SELECTED=0
for flow_file in "${FLOW_FILES[@]}"; do
  rel_flow="${flow_file#${REPO_ROOT}/}"
  if ! matches_tag_filters "${flow_file}"; then
    continue
  fi

  SELECTED=$((SELECTED + 1))
  if ! run_single_flow "${rel_flow}"; then
    FAILED+=("${rel_flow}")
  fi
done

if [[ "${SELECTED}" -eq 0 ]]; then
  echo "No Maestro flows matched the requested tag filters." >&2
  exit 1
fi

if [[ "${#FAILED[@]}" -gt 0 ]]; then
  echo "Maestro failed for ${#FAILED[@]} flow(s):" >&2
  printf '  - %s\n' "${FAILED[@]}" >&2
  exit 1
fi
