{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.wine;
in {
  meta.maintainers = with lib.maintainers; [ccicnce113424];

  options.programs.wine = {
    enable = lib.mkEnableOption "wine";
    package = lib.mkPackageOption pkgs "wine" {};
    binfmt = lib.mkEnableOption "binfmt support for wine";
    ntsync = lib.mkEnableOption "ntsync. Requires wine that supports ntsync. Only avaliable on Linux 6.14+";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    environment.sessionVariables.WINE_BIN = lib.getExe cfg.package;

    # add binfmt registration
    boot.binfmt.registrations."DOSWin" = lib.mkIf cfg.binfmt {
      wrapInterpreterInShell = false;
      interpreter = lib.getExe cfg.package;
      recognitionType = "magic";
      offset = 0;
      magicOrExtension = "MZ";
    };

    # load ntsync
    boot.kernelModules = lib.mkIf cfg.ntsync ["ntsync"];

    # make ntsync device accessible
    services.udev.packages =
      lib.mkIf cfg.ntsync
      [
        (pkgs.writeTextFile {
          name = "ntsync-udev-rules";
          text = ''KERNEL=="ntsync", MODE="0660", TAG+="uaccess"'';
          destination = "/etc/udev/rules.d/70-ntsync.rules";
        })
      ];

    assertions = [
      {
        assertion = cfg.ntsync -> lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14";
        message = "Option `programs.wine.ntsync` requires Linux 6.14+.";
      }
    ];
  };
}
