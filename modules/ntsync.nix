{
  pkgs,
  config,
  lib,
  ...
}: {
  options.programs.wine.ntsync.enable = lib.mkEnableOption "ntsync. Only avaliable on Linux 6.14+.";

  config = lib.mkIf config.programs.wine.ntsync.enable {
    # load ntsync
    boot.kernelModules = ["ntsync"];

    # make ntsync device accessible
    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "ntsync-udev-rules";
        text = ''KERNEL=="ntsync", MODE="0660", TAG+="uaccess"'';
        destination = "/etc/udev/rules.d/70-ntsync.rules";
      })
    ];

    assertions = [
      {
        assertion = lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14";
        message = "Option `programs.wine.ntsync.enable` requires Linux 6.14+.";
      }
    ];
  };
}
