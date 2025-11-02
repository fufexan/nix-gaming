{
  testers,
  nixosModules,
  writeShellScriptBin,
  lib,
  ...
}:
testers.nixosTest {
  name = "pipewire-low-latency";

  nodes.machine = {
    imports = [
      ../profiles/minimal.nix

      # get local pipewire low latency module
      nixosModules.pipewireLowLatency
    ];

    # pipewire config
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    systemd.user.services = {
      pipewire.wantedBy = ["default.target"];
      pipewire-pulse.wantedBy = ["default.target"];
    };
  };

  testScript = let
    checkDir = writeShellScriptBin "checkDir" ''
      if [ -e "$1" ]; then
        echo "File $1 exists."
      else
        echo "File $1 does not exist."
      fi
    '';
  in ''
    machine.wait_for_unit("multi-user.target")

    machine.succeed("${lib.getExe checkDir} /etc/pipewire/pipewire.d/99-lowlatency.conf")
    machine.succeed("${lib.getExe checkDir} /etc/pipewire/pipewire-pulse.d/99-lowlatency.conf")
  '';
}
