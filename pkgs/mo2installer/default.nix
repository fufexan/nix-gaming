{
  lib,
  callPackage,
  fetchFromGitHub,
  makeWrapper,
  curl,
  findutils,
  p7zip,
  protontricks,
  stdenv,
  zenity,
}: let
  version = "5.0.3";

  src = fetchFromGitHub {
    owner = "rockerbacon";
    repo = "modorganizer2-linux-installer";
    rev = "refs/tags/${version}";
    hash = "sha256-RYN5/t5Hmzu+Tol9iJ+xDmLGY9sAkLTU0zY6UduJ4i0=";
  };

  steam-redirector = callPackage ./steam-redirector.nix {inherit version src;};
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "mo2installer";
    inherit version src;

    nativeBuildInputs = [
      findutils
      makeWrapper
    ];

    installPhase = let
      path = "$out/share/mo2installer";
    in ''
      mkdir -p "$out/bin"

      rm -r ci/
      rm -r screenshots/
      rm README.md
      rm pack-release.sh
      rm post-install.md

      mv "install.sh" "${finalAttrs.pname}"

      mkdir -p "${path}"
      mkdir -p "$out/bin"

      cp -r ./* "${path}"
      ln -s ${steam-redirector}/main.exe ${path}/steam-redirector

      wrapProgram ${path}/${finalAttrs.pname} --prefix PATH : ${
        lib.makeBinPath
        [
          curl
          p7zip
          protontricks
          zenity
        ]
      }

      ln -s ${path}/${finalAttrs.pname} $out/bin

      cd ${path}/steam-redirector
      find . -type f -not -name "main.exe" | xargs rm
    '';

    meta = {
      description = "An easy-to-use Mod Organizer 2 installer for Linux";
      homepage = "https://github.com/rockerbacon/modorganizer2-linux-installer";
      license = lib.licenses.gpl3Only;
      mainProgram = "mo2installer";
      platforms = lib.platforms.linux;
    };
  })
