#!/usr/bin/env -S nix shell .#npins -c bash

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
