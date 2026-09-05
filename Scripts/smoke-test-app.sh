#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_path="${1:-$project_dir/build/EvoBar.app}"
binary="$app_path/Contents/MacOS/EvoBar"

if [[ ! -x "$binary" ]]; then
    echo "App executable not found: $binary" >&2
    exit 1
fi

smoke_root="$(mktemp -d "${TMPDIR:-/tmp}/EvoBarSmoke.XXXXXX")"
report="$smoke_root/report.json"
app_log="$smoke_root/app.log"
app_pid=""

cleanup() {
    if [[ -n "$app_pid" ]] && kill -0 "$app_pid" 2>/dev/null; then
        kill "$app_pid" 2>/dev/null || true
        wait "$app_pid" 2>/dev/null || true
    fi
    rm -rf "$smoke_root"
}
trap cleanup EXIT

EVOBAR_SMOKE_TEST_OUTPUT="$report" "$binary" >"$app_log" 2>&1 &
app_pid="$!"

for _ in {1..150}; do
    if [[ -f "$report" ]]; then
        break
    fi
    if ! kill -0 "$app_pid" 2>/dev/null; then
        break
    fi
    sleep 0.1
done

if [[ ! -f "$report" ]]; then
    echo "EvoBar did not produce a smoke-test report." >&2
    sed -n '1,120p' "$app_log" >&2
    exit 1
fi

status="$(plutil -extract status raw -o - "$report")"
detail="$(plutil -extract detail raw -o - "$report")"
if [[ "$status" != "ready" ]]; then
    echo "EvoBar smoke test failed: $detail" >&2
    sed -n '1,120p' "$app_log" >&2
    exit 1
fi

for _ in {1..30}; do
    if ! kill -0 "$app_pid" 2>/dev/null; then
        break
    fi
    sleep 0.1
done
if kill -0 "$app_pid" 2>/dev/null; then
    echo "EvoBar initialized but did not terminate smoke mode." >&2
    exit 1
fi
wait "$app_pid"
app_pid=""

echo "EvoBar app launch smoke test passed: $detail"
