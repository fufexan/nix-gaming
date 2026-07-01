#!/usr/bin/env -S nix shell .#npins nixpkgs#jq nixpkgs#gnugrep nixpkgs#gawk -c bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/update-wine-common.sh"

src="$(npins get-path wine-osu-patches)"

wine_commit="$(<"$src/wine-commit")"
staging_commit="$(<"$src/staging-commit")"

npins add gitlab --frozen --name wine-osu --server https://gitlab.winehq.org/ -b master --at "$wine_commit" wine wine
npins add gitlab --frozen --name wine-osu-staging --server https://gitlab.winehq.org/ -b master --at "$staging_commit" wine wine-staging

wine_src="$(npins get-path wine-osu)"
install_version "$wine_src" "pkgs/wine/wine-osu/VERSION"
extract_mono "$wine_src" "pkgs/wine/wine-osu/mono.json"
