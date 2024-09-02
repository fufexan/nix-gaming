{
  fetchFromGitHub,
  lib,
  pkgs,
  stdenv,
  ...
}: let
  steam-redirector = pkgs.callPackage ./steam-redirector.nix {inherit pkgs;};
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "mo2installer";
    version = "5.0.3";

    src = fetchFromGitHub {
      owner = "rockerbacon";
      repo = "modorganizer2-linux-installer";
      rev = "v{finalAttrs.version}";
      hash = "sha256-RYN5/t5Hmzu+Tol9iJ+xDmLGY9sAkLTU0zY6UduJ4i0=";
    };

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p "$out/bin"

      rm -r ci/
      rm -r screenshots/
      rm LICENSE
      rm README.md
      rm pack-release.sh
      rm post-install.md

      mv "install.sh" "${pname}"

      cp -r ./* "$out/bin"
      cp -r ${steam-redirector}/main.exe $out/bin/steam-redirector

      wrapProgram $out/bin/${pname} --prefix PATH : ${
        lib.makeBinPath (
          with pkgs; [
            bash
            curl
            p7zip
            protontricks
            zenity
          ]
        )
      }

      cd $out/bin/steam-redirector

      rm *.c
      rm Makefile
      rm README.md
      rm unix_utils.h
      rm win32_utils.h
    '';
  }
