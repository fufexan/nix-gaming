{
  nixosTest,
  nixosModules,
  writeShellScriptBin,
  lib,
  ...
}:
nixosTest {
  name = "pipewire-low-latency";

  nodes.machine = {
    imports = [
      ../profiles/minimal.nix

      # get local pipewire low latency module
      nixosModules.pipewireLowLatency
    ];

    hardware.pulseaudio.enable = lib.mkForce false;

    # pipewire config
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
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

    # lets see if our files are properly generated
    machine.succeed("${lib.getExe checkDir} /etc/wireplumber/main.lua.d/99-alsa-lowlatency.lua")
    machine.succeed("${lib.getExe checkDir} /etc/pipewire/pipewire.conf.d/99-lowlatency.conf")

    # make sure quantum is set properly
    # TODO: can this be done better?
    machine.succeed("pw-cli i all | grep min-quantum | grep 32")
  '';
}
