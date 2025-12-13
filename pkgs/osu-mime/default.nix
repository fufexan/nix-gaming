{
  lib,
  stdenvNoCC,
  fetchurl,
  librsvg,
  imagemagick,
  fetchgit,
}: let
  osu-web-rev = "96e384d5932c0113d1ad8fa8c6ac1052d1e22268";
  osu-mime-spec-rev = "a715a74c2188297e61ac629abaed27fa56f0538c";
in
  stdenvNoCC.mkDerivation {
    pname = "osu-mime";
    version = "unstable-2023-05-31";

    srcs = [
      (fetchurl {
        url = "https://raw.githubusercontent.com/ppy/osu-web/${osu-web-rev}/public/images/layout/osu-logo-triangles.svg";
        sha256 = "4a6vm4H6iOmysy1/fDV6PyfIjfd1/BnB5LZa3Z2noa8=";
      })
      (fetchurl {
        url = "https://raw.githubusercontent.com/ppy/osu-web/${osu-web-rev}/public/images/layout/osu-logo-white.svg";
        sha256 = "XvYBIGyvTTfMAozMP9gmr3uYEJaMcvMaIzwO7ZILrkY=";
      })
      (fetchgit {
        url = "https://aur.archlinux.org/osu-mime";
        rev = osu-mime-spec-rev;
        sha256 = "sha256-Ef/nApqNOD8mMqTxb0XV6oxgaYGweWsy9zUalgHruDM=";
      })
    ];

    nativeBuildInputs = [
      librsvg
      imagemagick
    ];

    dontUnpack = true;

    installPhase = ''
      # Turn $srcs into a bash array
      read -ra srcs <<< "$srcs"

      mime_dir="$out/share/mime/packages"
      hicolor_dir="$out/share/icons/hicolor"

      mkdir -p "$mime_dir" "$hicolor_dir"

      # Generate icons
      # Adapted from https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=osu-mime
      for size in 16 24 32 48 64 96 128 192 256 384 512 1024; do
          icon_dir="$hicolor_dir/''${size}x''${size}/apps"

          # Generate icon
          rsvg-convert -w "$size" -h "$size" -f png -o "osu-logo-triangles.png" "''${srcs[0]}"
          rsvg-convert -w "$size" -h "$size" -f png -o "osu-logo-white.png" "''${srcs[1]}"
          convert -composite "osu-logo-triangles.png" "osu-logo-white.png" -gravity center 'osu!.png'

          mkdir -p "$icon_dir"
          mv 'osu!.png' "$icon_dir"
      done

      cp "''${srcs[2]}/osu-file-extensions.xml" "$mime_dir/osu.xml"
    '';

    meta = with lib; {
      description = "MIME types for osu!";
      license = licenses.agpl3Only; # osu-web uses AGPL v3.0
      maintainers = with lib.maintainers; [PlayerNameHere];
      platforms = ["x86_64-linux"];
    };
  }
