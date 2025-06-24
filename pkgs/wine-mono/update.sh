#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq -c bash

set -eux

info="pkgs/wine-mono/info.json"
version="$(curl -fsSL "https://api.github.com/repos/wine-mono/wine-mono/releases/latest" | jq -r '.tag_name')"

oldversion=$(jq -r ".version" "$info")
url="https://github.com/wine-mono/wine-mono/releases/download/${version}/${version}-x86.msi"

if [ "$oldversion" != "$version" ]; then
  if output=$(nix store prefetch-file "$url" --json); then
    jq --arg version "$version" '.version = $version' <<<"$output" >"$info"
  else
    echo "wine-mono has a non-release update"
  fi
else
  echo "wine-mono is up to date."
fi
