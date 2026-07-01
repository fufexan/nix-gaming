#!/usr/bin/env bash
# Common functions for wine update scripts.
# Source this file — do not execute directly.

# extract_mono <wine-source-path> <mono-json-output-path>
# Reads MONO_VERSION and MONO_SHA from the wine source's addons.c,
# converts to nix sri format, and writes mono.json.
extract_mono() {
  local src="$1"
  local output="$2"
  local addons_file="$src/dlls/appwiz.cpl/addons.c"

  local mono_version
  mono_version="$(grep '#define MONO_VERSION' "$addons_file" | awk -F'"' '{print $2}' | head -n 1)"
  local mono_sha
  mono_sha="$(grep '#define MONO_SHA' "$addons_file" | awk -F'"' '{print $2}' | head -n 1)"

  local mono_url="https://dl.winehq.org/wine/wine-mono/$mono_version/wine-mono-$mono_version-x86.msi"
  local mono_hash
  mono_hash="$(nix hash convert --hash-algo sha256 --from base16 "$mono_sha")"

  jq -n \
    --arg url "$mono_url" \
    --arg hash "$mono_hash" \
    '{url: $url, hash: $hash}' >"$output"
}

# install_version <wine-source-path> <version-output-path>
# Copies the VERSION file from the wine source to the target path.
install_version() {
  install -D "$1/VERSION" "$2"
}
