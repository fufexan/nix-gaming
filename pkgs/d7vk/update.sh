#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq .#npins -c bash

set -eu

releases="$(curl -fsSL "https://api.github.com/repos/WinterSnowfall/d7vk/releases")"
version=$(jq -r '.[0].tag_name' <<<"$releases")

npins add github --submodules --frozen --at $version WinterSnowfall d7vk
