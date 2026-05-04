#!/usr/bin/env bash
# Restaure la status bar du simulateur (network back online)
set -euo pipefail
xcrun simctl status_bar booted clear
