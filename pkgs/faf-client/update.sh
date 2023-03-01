#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq nixpkgs#gnugrep nixpkgs#gnused -c bash

set -euo pipefail

filePath="pkgs/faf-client/default.nix"

dry_run=
while test $# != 0
do
    case "$1" in
    -d|--dry-run) dry_run=1 ;;
    esac
    shift
done

# get string variable contents from the nix file
function getValue()
{
    grep "$1 = " $filePath | sed 's/.*= "//g' | sed 's/".*//g'
}
function calcHash()
{
    (nix-build --no-out-link -A "$1" || true) |& grep --perl-regexp --only-matching 'got: +.+[:-]\K.+'
}
function replaceInFile()
{
    if [ -n "$dry_run" ]; then
        echo "will replace "'`'"$1"'`'" with "'`'"$2"'`'
    else
        sed -i "s/$1/$2/g" "$filePath"
    fi
}

releaseData="$(curl -s https://api.github.com/repos/FAForever/downlords-faf-client/releases | cat -v | tr '\n' ' ')"

versionStable="$(
    echo "$releaseData" |
    jq '.[] | select(.prerelease!=true) | .tag_name' --raw-output |
    head -n1 | tail -c +2
)"
versionUnstable="$(
    echo "$releaseData" |
    jq '.[] | .tag_name' --raw-output |
    head -n1 | tail -c +2
)"

echo "Stable version: $versionStable"
echo "Unstable version: $versionUnstable"

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
    replaceInFile "$oldVersionStable" "$versionStable"

    replaceInFile "$oldSha256Stable" "$fakeSha256_1"
    if [ -z "$dry_run" ]; then
        sha256Stable=$(calcHash "packages.$system.faf-client")
        replaceInFile "$fakeSha256_1" "$sha256Stable"
    fi
fi

oldVersionUnstable=$(getValue versionUnstable)
oldSha256Unstable=$(getValue sha256Unstable)

if [[ "$oldVersionUnstable" = "$versionUnstable" ]]; then
    echo "no unstable faf updates"
else
    echo "updating unstable: $oldVersionUnstable->$versionUnstable"
    replaceInFile "versionUnstable = \"$oldVersionUnstable" "versionUnstable = \"$versionUnstable"

    replaceInFile "sha256Unstable = \"$oldSha256Unstable" "sha256Unstable = \"$fakeSha256_2"
    if [ -z "$dry_run" ]; then
        sha256Unstable=$(calcHash "packages.$system.faf-client-unstable")
        replaceInFile "$fakeSha256_2" "$sha256Unstable" $filePath
    fi
fi

echo "done!"

