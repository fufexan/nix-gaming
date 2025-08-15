{fetchurl, ...}: let
  # can be updated using `pkgs/wine-mono/update.sh`
  info = builtins.fromJSON (builtins.readFile ./info.json);
in
  fetchurl rec {
    inherit (info) version hash;
    url = "https://github.com/wine-mono/wine-mono/releases/download/${version}/${version}-x86.msi";
  }
