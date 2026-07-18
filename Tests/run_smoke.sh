#!/bin/sh
# Smoke test for the widget deep-link path (AppDeepLink parsing + chip URL round-trip).
# Usage: sh Tests/run_smoke.sh
set -e
cd "$(dirname "$0")/.."
swiftc -o /tmp/eternal_smoke Shared/AppDeepLink.swift Tests/DeepLinkSmokeTest/main.swift
/tmp/eternal_smoke
