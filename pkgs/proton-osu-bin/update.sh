#!/usr/bin/env -S nix shell nixpkgs#jq -c bash

info="pkgs/proton-osu-bin/info.json"
version=$(jq -r '.pins."proton-osu".version' npins/sources.json)
oldversion=$(jq -r '.version' "$info")
url="https://github.com/whrvt/umubuilder/releases/download/${version}/${version}.tar.xz"

if [ "$oldversion" != "$version" ]; then
  if output=$(nix store prefetch-file "$url" --json --unpack); then
    jq --arg version "$version" '.version = $version' <<<"$output" >"$info"
  else
    echo "proton-osu has a release without build artifacts"
  fi
else
  echo "proton-osu is up to date"
fi
