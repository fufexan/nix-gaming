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
  }: let
    deprecationNotices = {
      umu = self.lib.mkDeprecated "warn" config.packages.umu-launcher-git {
        name = "umu";
        target = "package";
        date = "2025-02-04";
        instructions = ''
          This package has been renamed to `umu-launcher-git` to differentiate
          itself from the package in nixpkgs.
        '';
      };
      umu-launcher = self.lib.mkDeprecated "warn" config.packages.umu-launcher-git {
        name = "umu";
        target = "package";
        date = "2025-12-06";
        instructions = ''
          This package has been renamed to `umu-launcher-git` to differentiate
          itself from the package in nixpkgs.
        '';
      };
      umu-launcher-unwrapped = self.lib.mkDeprecated "warn" config.packages.umu-launcher-unwrapped-git {
        name = "umu";
        target = "package";
        date = "2025-12-06";
        instructions = ''
          This package has been renamed to `umu-launcher-unwrapped-git` to differentiate
          itself from the package in nixpkgs.
        '';
      };
    };

    packages' = let
      pins = builtins.mapAttrs (_: p: p {inherit pkgs;}) (import ../npins {});

      wine-mono = pkgs.callPackage ./wine-mono {};

      wineBuilder = wine: build: extra:
        (import ./wine (
          {
            inherit
              inputs
              self
              pkgs
              build
              pins
              wine-mono
              ;
            inherit
              (pkgs)
              callPackage
              fetchFromGitHub
              replaceVars
              lib
              moltenvk
              pkgsCross
              pkgsi686Linux
              stdenv
              wrapCCMulti
              overrideCC
              gcc13
              ;
            supportFlags = (import ./wine/supportFlags.nix).${build};
          }
          // extra
        )).${
          wine
        };
    in {
      inherit wine-mono;

      umu-launcher-unwrapped-git =
        (pkgs.callPackage "${pins.umu-launcher}/packaging/nix/unwrapped.nix" {
          inherit (pkgs) umu-launcher-unwrapped;
          version = builtins.substring 0 7 pins.umu-launcher.revision;
        }).overrideAttrs
        {
          # 2025-12-08: Tests and versionCheckHook are currently broken
          doInstallCheck = false;
        };
      umu-launcher-git = pkgs.callPackage "${pins.umu-launcher}/packaging/nix/package.nix" {
        inherit (pkgs) umu-launcher;
        umu-launcher-unwrapped = config.packages.umu-launcher-unwrapped-git;
      };

      cnc-ddraw = pkgs.callPackage ./cnc-ddraw {};

      d7vk-w32 = pkgs.pkgsCross.mingw32.callPackage ./d7vk {inherit pins;};

      dxvk = pkgs.callPackage ./dxvk {inherit pins;};
      dxvk-w32 = pkgs.pkgsCross.mingw32.callPackage ./dxvk {inherit pins;};
      dxvk-w64 = pkgs.pkgsCross.mingwW64.callPackage ./dxvk {inherit pins;};

      dxvk-nvapi = pkgs.callPackage ./dxvk {inherit pins;};
      dxvk-nvapi-w32 = pkgs.pkgsCross.mingw32.callPackage ./dxvk-nvapi {inherit pins;};
      dxvk-nvapi-w64 = pkgs.pkgsCross.mingwW64.callPackage ./dxvk-nvapi {inherit pins;};

      dxvk-nvapi-vkreflex-layer = pkgs.callPackage ./dxvk-nvapi/vkreflex-layer.nix {inherit pins;};

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
        inherit (config.packages) osu-mime;
      };

      osu-lazer-tachyon-bin = pkgs.callPackage ./osu-lazer-bin {
        inherit (config.packages) osu-mime;
        releaseStream = "tachyon";
      };

      osu-stable = pkgs.callPackage ./osu-stable {
        inherit (config.packages) osu-mime proton-osu-bin umu-launcher-git;
        wine = config.packages.wine-osu;
        wine-discord-ipc-bridge = config.packages.wine-discord-ipc-bridge.override {
          wine = config.packages.wine-osu;
        };
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

      proton-osu-bin = pkgs.callPackage ./proton-osu-bin {inherit pins;};

      roblox-player = pkgs.callPackage ./roblox-player {
        wine = config.packages.wine-tkg;
        inherit (config.packages) wine-discord-ipc-bridge;
      };

      rocket-league = pkgs.callPackage ./rocket-league {
        wine = config.packages.wine-tkg;
        inherit (config.packages) umu;
      };

      rpc-bridge = pkgs.callPackage ./rpc-bridge {inherit pins;};

      star-citizen = pkgs.callPackage ./star-citizen {
        wine = config.packages.wine-tkg;
        winetricks = config.packages.winetricks-git;

        inherit (config.packages) umu-launcher-git wineprefix-preparer;
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

      wine-cachyos = wineBuilder "wine-cachyos" "full" {};

      wine-ge = wineBuilder "wine-ge" "full" {};

      wine-osu = wineBuilder "wine-osu" "base" {};

      wine-tkg = wineBuilder "wine-tkg" "full" {};

      winetricks-git = pkgs.callPackage ./winetricks-git {inherit pins;};

      wineprefix-preparer = pkgs.callPackage ./wineprefix-preparer {
        inherit
          (config.packages)
          dxvk-w32
          vkd3d-proton-w32
          dxvk-w64
          vkd3d-proton-w64
          dxvk-nvapi-w32
          dxvk-nvapi-w64
          cnc-ddraw
          d7vk-w32
          ;
      };
    };
  in {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    overlayAttrs = packages';

    packages = packages' // deprecationNotices;
  };
}
