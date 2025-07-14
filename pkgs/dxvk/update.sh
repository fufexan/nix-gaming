#!/usr/bin/env -S nix shell .#npins nixpkgs#jq -c bash

NAME="dxvk"

REPO_OWNER="doitsujin"
REPO_NAME="dxvk"

GPLASYNC_VERSION=$(jq -r '.pins."dxvk-gplasync".version' npins/sources.json)
VERSION="${GPLASYNC_VERSION%%-*}"

npins add github --frozen --submodules --name "$NAME" --at "$VERSION" "$REPO_OWNER" "$REPO_NAME"
