#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq -c bash

set -eux

info="pkgs/cnc-ddraw/info.json"
version="$(curl -fsSL "https://api.github.com/repos/FunkyFr3sh/cnc-ddraw/releases/latest" | jq -r '.tag_name')"

oldversion=$(jq -r ".version" "$info")
url="https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/${version}/cnc-ddraw.zip"

if [ "$oldversion" != "$version" ]; then
  if output=$(nix store prefetch-file "$url" --json --unpack); then
    jq --arg version "$version" '.version = $version' <<<"$output" >"$info"
  else
    echo "cnc-ddraw has a non-release update"
  fi
else
  echo "cnc-ddraw is up to date."
fi
