{
  stdenv,
  lib,
  pins,
  pkgsCross,
}: let
  inherit (pins) rpc-bridge;
in
  stdenv.mkDerivation {
    pname = "rpc-bridge";
    version = lib.removePrefix "v" rpc-bridge.version;

    src = rpc-bridge;

    nativeBuildInputs = [
      pkgsCross.mingwW64.stdenv.cc
    ];

    makeFlags = [
      "GIT_COMMIT=${builtins.substring 0 7 rpc-bridge.revision}"
      "GIT_BRANCH=master"
    ];

    enableParallelBuilding = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin

      cp build/bridge.exe $out/bin

      ${
        if stdenv.isDarwin
        then ''
          cp build/launchd.sh $out/bin
        ''
        else ''
          cp build/bridge.sh $out/bin
        ''
      }

      runHook postInstall
    '';

    meta = {
      description = "Discord RPC Bridge for Wine";
      homepage = "https://github.com/EnderIce2/rpc-bridge";
      maintainers = with lib.maintainers; [ccicnce113424];
      platforms = lib.platforms.unix;
      license = lib.licenses.mit;
    };
  }
