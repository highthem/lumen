#!/usr/bin/env bash
# Force le simulateur booted en mode "no network" pour tester offline + queued AI
set -euo pipefail
xcrun simctl status_bar booted override --dataNetwork hide --wifiBars 0
