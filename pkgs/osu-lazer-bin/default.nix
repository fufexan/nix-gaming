{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
  symlinkJoin,
  gamemode,
  pipewire_latency ? "64/48000", # reasonable default
  gmrun_enable ? true, # keep this flag for compatibility
  command_prefix ?
    if gmrun_enable
    # won't hurt users even if they don't have it set up
    then "${gamemode}/bin/gamemoderun"
    else null,
  postExtract ? "",
  releaseStream ? "lazer",
  osu-mime,
}: let
  pname = "osu-lazer-bin";
  info = (builtins.fromJSON (builtins.readFile ./info.json)).${releaseStream};
  inherit (info) version;

  src = fetchurl {
    url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
    inherit (info) hash;
  };

  derivation = let
    contents = appimageTools.extract {inherit pname version src postExtract;};
  in
    appimageTools.wrapAppImage {
      inherit version pname;
      src = contents;

      extraPkgs = pkgs: [pkgs.icu];

      extraInstallCommands = ''
        . ${makeWrapper}/nix-support/setup-hook
        mv -v $out/bin/${pname} $out/bin/osu!

        wrapProgram $out/bin/osu! \
          --set PIPEWIRE_LATENCY "${pipewire_latency}" \
          --set OSU_EXTERNAL_UPDATE_PROVIDER "1" \
          --set OSU_EXTERNAL_UPDATE_STREAM "${releaseStream}" \
          --set vblank_mode "0"

        ${
          # a hack to infiltrate the command in the wrapper
          lib.optionalString (builtins.isString command_prefix) ''
            sed -i '$s:exec -a "$0":exec ${command_prefix}:' $out/bin/osu!
          ''
        }

        install -m 444 -D ${contents}/osu!.desktop -t $out/share/applications
        for i in 16 32 48 64 96 128 256 512 1024; do
          install -D ${contents}/osu.png $out/share/icons/hicolor/''${i}x$i/apps/osu.png
        done
      '';
    };
in
  symlinkJoin {
    name = "${pname}-${version}";
    paths = [
      derivation
      osu-mime
    ];

    meta = {
      description = "Rhythm is just a *click* away";
      longDescription = "osu-lazer extracted from the official AppImage to retain multiplayer support.";
      homepage = "https://osu.ppy.sh";
      license = with lib.licenses; [
        mit
        cc-by-nc-40
        unfreeRedistributable # osu-framework contains libbass.so in repository
      ];
      mainProgram = "osu!";
      passthru.updateScript = ./update.sh;
      platforms = ["x86_64-linux"];
    };
  }
