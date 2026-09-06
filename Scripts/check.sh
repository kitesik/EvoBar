#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cache_base="${XDG_CACHE_HOME:-${HOME}/Library/Caches}"
scratch_dir="${EVOBAR_SWIFTPM_SCRATCH:-$cache_base/EvoBar/SwiftPM}"

cd "$project_dir"
"$project_dir/Scripts/test-storefront-configuration.sh"
swift build --scratch-path "$scratch_dir"
swift test --scratch-path "$scratch_dir"
