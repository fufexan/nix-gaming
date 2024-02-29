{
  nixosTest,
  nixosModules,
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

    systemd.user.services = {
      pipewire.wantedBy = ["default.target"];
      pipewire-pulse.wantedBy = ["default.target"];
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # make sure quantum is set properly
    # TODO: can this be done better?
    machine.succeed("pw-cli i all | grep min-quantum | grep 32")
  '';
}
