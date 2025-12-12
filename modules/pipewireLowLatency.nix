{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) int str bool;

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
        description = "Nominal graph sample rate";
        type = int;
        default = 48000;
        example = 96000;
      };

      alsa = {
        enable = mkOption {
          description = ''
            ALSA-level low-latency overrides via WirePlumber.

            This tweaks format, hardware rate and period size for *matching devices*
            only.

            WARNING:  Enabling this with default settings may break devices that don't
            support the specified format/rate (e.g., HDMI sinks that only support
            48 kHz / S16_LE).
          '';
          type = bool;
          default = false;
        };

        devicePattern = mkOption {
          description = ''
            WirePlumber `node.name` pattern to match devices that should get
            ALSA low-latency overrides.

            Use `pw-dump | grep node.name | grep alsa_output` or
            `wpctl status` followed by `wpctl inspect <id>` to find the right names.
          '';
          type = str;
          default = "~alsa_output.*";
          example = "~alsa_output.usb-Generic_USB_Audio-00.*";
        };

        format = mkOption {
          description = "Target audio format for ALSA (e.g. S16_LE, S24_3LE, S32LE)";
          type = str;
          default = "S32LE";
          example = "S24_3LE";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.pipewire = {
      # make sure PipeWire is enabled if the module is imported
      # and low latency is enabled
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

      # ensure WirePlumber is enabled explicitly
      # and write extra config to ship low latency rules for alsa
      wireplumber = {
        enable = true;
        extraConfig = mkIf cfg.alsa.enable {
          "99-alsa-lowlatency"."monitor.alsa.rules" = [
            {
              matches = [{"node.name" = cfg.alsa.devicePattern;}];
              actions.update-props = {
                "audio.format" = cfg.alsa.format;
                "audio.rate" = cfg.rate;
              };
            }
          ];
        };
      };
    };
  };
}
