{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) int;

  cfg = config.services.pipewire.lowLatency;
  qr = "${toString cfg.quantum}/${toString cfg.rate}";
in {
  # low-latency PipeWire configuration
  # extends the nixpkgs module
  meta.maintainers = with lib.maintainers; [fufexan];

  options = {
    services.pipewire.lowLatency = {
      enable = mkEnableOption ''
        low latency for PipeWire. This will also set `services.pipewire.enable` and
        `services.pipewire.wireplumber.enable` to true.
      '';

      quantum = mkOption {
        description = "Minimum quantum to set";
        type = int;
        default = 64;
        example = 32;
      };

      rate = mkOption {
        description = "Rate to set";
        type = int;
        default = 48000;
        example = 96000;
      };
    };
  };

  config = mkIf cfg.enable {
    services.pipewire = {
      # make sure PipeWire is enabled if the module is imported
      # and low latency is enabledd
      enable = true;

      # write extra config
      extraConfig = {
        pipewire."99-lowlatency" = {
          "context.properties"."default.clock.min-quantum" = cfg.quantum;

          "context.modules" = [
            {
              name = "libpipewire-module-rt";
              flags = [
                "ifexists"
                "nofail"
              ];
              args = {
                "nice.level" = -15;
                "rt.prio" = 88;
                "rt.time.soft" = 200000;
                "rt.time.hard" = 200000;
              };
            }
          ];
        };

        pipewire-pulse."99-lowlatency"."pulse.properties" = {
          "server.address" = ["unix:native"];
          "pulse.min.req" = qr;
          "pulse.min.quantum" = qr;
          "pulse.min.frag" = qr;
        };

        client."99-lowlatency"."stream.properties" = {
          "node.latency" = qr;
          "resample.quality" = 1;
        };
      };

      # ensure WirePlumber is enabled explicitly (defaults to true while PW is enabled)
      # and write extra config to ship low latency rules for alsa

      wireplumber = {
        enable = true;
        extraConfig."99-alsa-lowlatency"."monitor.alsa.rules" = [
          {
            matches = [{"node.name" = "~alsa_output.*";}];
            actions.update-props = {
              "audio.format" = "S32LE";
              "audio.rate" = cfg.rate * 2;
              "api.alsa.period-size" = 2;
            };
          }
        ];
      };
    };
  };
}
