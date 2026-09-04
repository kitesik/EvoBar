#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
archive="${1:-}"
version="${EVOBAR_RELEASE_VERSION:-}"
template="$project_dir/Packaging/homebrew/evobar.rb.template"
output="$project_dir/build/release/EvoBar.rb"

if [[ -z "$archive" || ! -f "$archive" ]]; then
    echo "Usage: EVOBAR_RELEASE_VERSION=x.y.z $0 <release-archive.zip>" >&2
    exit 1
fi
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "EVOBAR_RELEASE_VERSION must be a semantic version" >&2
    exit 1
fi

sha256="$(shasum -a 256 "$archive" | awk '{print $1}')"
sed \
    -e "s/__VERSION__/$version/g" \
    -e "s/__SHA256__/$sha256/g" \
    "$template" > "$output"

ruby -c "$output" >/dev/null
echo "$output"
