{
  lib,
  fetchzip,
}: let
  info = lib.importJSON ./info.json;
in
  fetchzip {
    inherit (info) hash;
    version = lib.removePrefix "v" info.version;
    url = "https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/${info.version}/cnc-ddraw.zip";
    stripRoot = false;
  }
