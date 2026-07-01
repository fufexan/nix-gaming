#!/usr/bin/env -S nix shell .#npins nixpkgs#jq nixpkgs#gnugrep nixpkgs#gawk -c bash
set -euo pipefail

src="$(npins get-path wine-osu-patches)"

wine_commit="$(<"$src/wine-commit")"
staging_commit="$(<"$src/staging-commit")"

npins add gitlab --frozen --name wine-osu --server https://gitlab.winehq.org/ -b master --at "$wine_commit" wine wine
npins add gitlab --frozen --name wine-osu-staging --server https://gitlab.winehq.org/ -b master --at "$staging_commit" wine wine-staging

wine_src="$(npins get-path wine-osu)"
install -D "$wine_src/VERSION" pkgs/wine/wine-osu/VERSION

addons_file="$wine_src/dlls/appwiz.cpl/addons.c"

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
  '{url: $url, hash: $hash}' >pkgs/wine/wine-osu/mono.json
