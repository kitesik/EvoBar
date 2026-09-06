#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cache_base="${XDG_CACHE_HOME:-${HOME}/Library/Caches}"
scratch_dir="${EVOBAR_SWIFTPM_SCRATCH:-$cache_base/EvoBar/SwiftPM}"
developer_dir="$(xcode-select -p)"

cd "$project_dir"
"$project_dir/Scripts/test-storefront-configuration.sh"
swift build --scratch-path "$scratch_dir"

if [[ "$developer_dir" == *CommandLineTools ]]; then
    # A Command Line Tools install ships swift-testing but leaves its runtime
    # interop library off the default framework and rpath search paths.
    frameworks="$developer_dir/Library/Developer/Frameworks"
    interop="$developer_dir/Library/Developer/usr/lib"
    export DYLD_FRAMEWORK_PATH="$frameworks${DYLD_FRAMEWORK_PATH:+:$DYLD_FRAMEWORK_PATH}"
    export DYLD_LIBRARY_PATH="$interop${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
    swift test --scratch-path "$scratch_dir" \
        -Xswiftc -F -Xswiftc "$frameworks" \
        -Xlinker -rpath -Xlinker "$frameworks" \
        -Xlinker -rpath -Xlinker "$interop"
else
    swift test --scratch-path "$scratch_dir"
fi
