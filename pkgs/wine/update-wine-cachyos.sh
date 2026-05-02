#!/usr/bin/env -S nix shell .#npins nixpkgs#jq nixpkgs#gnugrep nixpkgs#gawk -c bash

REPO_OWNER="CachyOS"
REPO_NAME="wine-cachyos"

SRCINFO_URL="https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/refs/heads/master/wine-cachyos/.SRCINFO"

srcinfo_content="$(curl -fsSL "$SRCINFO_URL")"

# Extract tag from a line like:
#   source = wine-cachyos::git+https://github.com/CachyOS/wine-cachyos.git#tag=cachyos-10.0-20260101-wine
tag="$(
  printf '%s\n' "$srcinfo_content" |
    grep -Eo '#tag=[^[:space:]]+' |
    head -n 1 |
    sed 's/^#tag=//'
)"

if [ -z "$tag" ]; then
  echo "error: could not extract tag from $SRCINFO_URL" >&2
  exit 1
fi

npins add github --frozen --at "$tag" "$REPO_OWNER" "$REPO_NAME"

src="$(npins get-path wine-cachyos)"
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
  '{url: $url, hash: $hash}' >pkgs/wine/wine-cachyos/mono.json
