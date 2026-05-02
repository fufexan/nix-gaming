#!/usr/bin/env -S nix shell .#npins nixpkgs#jq nixpkgs#gnugrep nixpkgs#gawk -c bash
set -euo pipefail

src="$(npins get-path wine-tkg)"
install -D "$src/VERSION" pkgs/wine/wine-tkg/VERSION

addons_file="$src/dlls/appwiz.cpl/addons.c"

mono_version="$(
  grep '#define MONO_VERSION' "$addons_file" | awk -F'"' '{print $2}' | head -n 1
)"
mono_sha="$(
  grep '#define MONO_SHA' "$addons_file" | awk -F'"' '{print $2}' | head -n 1
)"

mono_url="https://dl.winehq.org/wine/wine-mono/$mono_version/wine-mono-$mono_version-x86.msi"
mono_hash="$(
  nix hash convert --hash-algo sha256 --from base16 "$mono_sha"
)"

jq -n \
  --arg url "$mono_url" \
  --arg hash "$mono_hash" \
  '{url: $url, hash: $hash}' >pkgs/wine/wine-tkg/mono.json
