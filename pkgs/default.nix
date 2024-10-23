{
  inputs,
  self,
  ...
}: {
  systems = ["x86_64-linux"];

  imports = [inputs.flake-parts.flakeModules.easyOverlay];

  perSystem = {
    config,
    system,
    pkgs,
    ...
  }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    overlayAttrs = config.packages;

    packages = let
      pins = import ../npins;

      wineBuilder = wine: build: extra:
        (import ./wine ({
            inherit inputs self pkgs build pins;
            inherit (pkgs) callPackage fetchFromGitHub fetchurl lib moltenvk pkgsCross pkgsi686Linux stdenv_32bit;
            supportFlags = (import ./wine/supportFlags.nix).${build};
          }
          // extra))
        .${wine};
    in {
      inherit (inputs.umu.packages.${system}) umu;
      dxvk = pkgs.callPackage ./dxvk {inherit pins;};
      dxvk-w32 = pkgs.pkgsCross.mingw32.callPackage ./dxvk {inherit pins;};
      dxvk-w64 = pkgs.pkgsCross.mingwW64.callPackage ./dxvk {inherit pins;};

      faf-client = pkgs.callPackage ./faf-client {inherit pins;};
      faf-client-unstable = pkgs.callPackage ./faf-client {
        inherit pins;
        unstable = true;
      };
      faf-client-bin = pkgs.callPackage ./faf-client/bin.nix {};
      faf-client-unstable-bin = pkgs.callPackage ./faf-client/bin.nix {unstable = true;};

      # broken upstream, thanks tauri
      # flight-core = pkgs.callPackage ./titanfall/flight-core.nix {};

      mo2installer = pkgs.callPackage ./mo2installer {};

      modrinth-app = pkgs.callPackage ./modrinth-app {};

      northstar-proton = pkgs.callPackage ./titanfall/northstar-proton.nix {};

      osu-mime = pkgs.callPackage ./osu-mime {};

      osu-lazer-bin = pkgs.callPackage ./osu-lazer-bin {
        inherit pins;
        inherit (config.packages) osu-mime;
      };

      osu-stable = pkgs.callPackage ./osu-stable {
        inherit (config.packages) osu-mime;
        wine = config.packages.wine-osu;
        wine-discord-ipc-bridge = config.packages.wine-discord-ipc-bridge.override {wine = config.packages.wine-osu;};
      };

      proton-ge = self.lib.mkDeprecated "warn" pkgs.emptyFile {
        name = "proton-ge";
        target = "package";
        date = "2024-03-17";
        instructions = ''
          You should use proton-ge-bin from Nixpkgs, which conforms to
          the new `extraCompatTools` module option under `programs.steam`
          For details, see the relevant pull request:

          <https://github.com/NixOS/nixpkgs/pull/296009>
        '';
      };

      roblox-player = pkgs.callPackage ./roblox-player {
        wine = config.packages.wine-tkg;
        inherit (config.packages) wine-discord-ipc-bridge;
      };

      rocket-league = pkgs.callPackage ./rocket-league {
        wine = config.packages.wine-tkg;
        inherit (config.packages) umu;
      };

      star-citizen = pkgs.callPackage ./star-citizen {
        wine = pkgs.wineWowPackages.staging;
        winetricks = config.packages.winetricks-git;
        inherit (config.packages) umu;
      };
      star-citizen-umu = config.packages.star-citizen.override {useUmu = true;};

      technic-launcher = pkgs.callPackage ./technic-launcher {};

      tmodloader = pkgs.callPackage ./tmodloader {
        dotnet = pkgs.dotnet-runtime_6;
      };

      viper = pkgs.callPackage ./titanfall/viper.nix {};

      vkd3d-proton = pkgs.callPackage ./vkd3d-proton {inherit pins;};
      vkd3d-proton-w32 = pkgs.pkgsCross.mingw32.callPackage ./vkd3d-proton {inherit pins;};
      vkd3d-proton-w64 = pkgs.pkgsCross.mingwW64.callPackage ./vkd3d-proton {inherit pins;};

      wine-discord-ipc-bridge = pkgs.callPackage ./wine-discord-ipc-bridge {
        inherit pins;
        wine = config.packages.wine-tkg;
      };

      # broken
      #winestreamproxy = callPackage ./winestreamproxy { wine = wine-tkg; };

      wine-ge = wineBuilder "wine-ge" "full" {};

      wine-osu = wineBuilder "wine-osu" "base" {};

      wine-tkg = wineBuilder "wine-tkg" "full" {};

      winetricks-git = pkgs.callPackage ./winetricks-git {inherit pins;};

      wineprefix-preparer = pkgs.callPackage ./wineprefix-preparer {inherit (config.packages) dxvk-w32 vkd3d-proton-w32 dxvk-w64 vkd3d-proton-w64;};
    };
  };
}
