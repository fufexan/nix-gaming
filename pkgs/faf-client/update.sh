#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq nixpkgs#gnugrep nixpkgs#gnused -c bash

set -euo pipefail

filePath="pkgs/faf-client/default.nix"

# get string variable contents from the nix file
function getValue()
{
    grep "$1 = " $filePath | sed 's/.*= "//g' | sed 's/".*//g'
}
function calcHash()
{
    (nix-build --no-out-link -A "$1" || true) |& grep --perl-regexp --only-matching 'got: +.+[:-]\K.+'
}

releaseData="$(curl -s https://api.github.com/repos/FAForever/downlords-faf-client/releases)"

versionStable="$(
    echo "$releaseData" |
    jq '.[] | select(.prerelease!=true) | .tag_name' --raw-output |
    sort --version-sort --reverse |
    head -n1 | tail -c +2
)"
versionUnstable="$(
    echo "$releaseData" |
    jq '.[] | .tag_name' --raw-output |
    sort --version-sort --reverse |
    head -n1 | tail -c +2
)"

system=$(nix-instantiate --eval -E 'builtins.currentSystem' | tr -d '"')

# in case the script fails during unstable hash calculation, it won't acceidentally rewrite unstable hash with new stable hash
fakeSha256_1="0000000000000000000000000000000000000000000000000000000000000001"
fakeSha256_2="0000000000000000000000000000000000000000000000000000000000000002"

oldVersionStable=$(getValue versionStable)
oldSha256Stable=$(getValue sha256Stable)

if [[ "$oldVersionStable" = "$versionStable" ]]; then
    echo "no stable faf updates"
else
    echo "updating stable: $oldVersionStable->$versionStable"

    # this might update the unstable version, and that's intended
    # in case there's no unstable version right now
    sed -i "s/$oldVersionStable/$versionStable/g" $filePath

    sed -i "s/$oldSha256Stable/$fakeSha256_1/g" $filePath
    sha256Stable=$(calcHash "packages.$system.faf-client")
    sed -i "s/$fakeSha256_1/$sha256Stable/g" $filePath
fi

oldVersionUnstable=$(getValue versionUnstable)
oldSha256Unstable=$(getValue sha256Unstable)

if [[ "$oldVersionUnstable" = "$versionUnstable" ]]; then
    echo "no unstable faf updates"
else
    echo "updating unstable: $oldVersionUnstable->$versionUnstable"
    sed -i "s/versionUnstable = \"$oldVersionUnstable/versionUnstable = \"$versionUnstable/g" $filePath

    sed -i "s/sha256Unstable = \"$oldSha256Unstable/sha256Unstable = \"$fakeSha256_2/g" $filePath
    sha256Unstable=$(calcHash "packages.$system.faf-client-unstable")
    sed -i "s/$fakeSha256_2/$sha256Unstable/g" $filePath
fi

echo "done!"

