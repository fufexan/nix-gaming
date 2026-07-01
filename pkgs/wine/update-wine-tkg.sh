#!/usr/bin/env -S nix shell .#npins nixpkgs#jq nixpkgs#gnugrep nixpkgs#gawk -c bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/update-wine-common.sh"

src="$(npins get-path wine-tkg)"
install_version "$src" "pkgs/wine/wine-tkg/VERSION"
extract_mono "$src" "pkgs/wine/wine-tkg/mono.json"
