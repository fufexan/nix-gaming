{
  lib,
  stdenv,
  fetchzip,
  steam-run,
  dotnet,
  runtimeDir ? "\\$HOME/.local/share/tmodloader",
  ...
}: let
  pname = "tModLoader";
  version = "2023.11.3.3";
in
  stdenv.mkDerivation {
    inherit pname version;

    src = fetchzip {
      url = "https://github.com/tModLoader/${pname}/releases/download/v${version}/tModLoader.zip";
      hash = "sha256-5sqSBGgsHcFQVAvwHFOUYz5UtVOjOP2mD1uqkGzOnL8=";
      stripRoot = false;
    };

    installPhase = ''
      mkdir -p $out/{bin,share}

      # move relevant files to $out/share
      # removing any of those files causes the game
      # to violently combust while launching
      cp -r \
        $src/DedicatedServerUtils \
        $src/LaunchUtils \
        $src/Libraries \
        $src/tModPorter \
        $src/tModLoader.deps.json \
        $src/tModLoader.dll \
        $src/tModLoader.pdb \
        $src/tModLoader.runtimeconfig.dev.json \
        $src/tModLoader.runtimeconfig.json \
        $src/tModLoader.xml \
        $src/serverconfig.txt \
        $out/share

      # make dll file executable
      chmod +x $out/share/tModLoader.dll

      # write a wrapper script that executes the correct file
      cat > $out/bin/${pname} <<EOF
      #!${stdenv.shell} -e

      unset SDL_VIDEODRIVER

      if ! [ -d "${runtimeDir}" ]; then
        echo "Creating runtime directory at ${runtimeDir}"
        mkdir -p "${runtimeDir}"
      fi

      ln -sf $out/share/* "${runtimeDir}/"
      cd "${runtimeDir}"

      # TODO: can there be a better way than using steam-run? the exact requirements
      # of a possible non-FHS env needs to be tested
      ${steam-run}/bin/steam-run ${dotnet}/bin/dotnet $out/share/tModLoader.dll
      EOF

      # make the script executable
      chmod +x $out/bin/${pname}
    '';

    meta = {
      description = "A mod to make and play Terraria mods.";
      homepage = "https://github.com/tModLoader/tModLoader";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [NotAShelf];
      mainPlatform = "tmodloader";
      platforms = lib.platforms.all;
    };
  }
