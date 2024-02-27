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
      enable = mkEnableOption "low latency for PipeWire";

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
    services.pipewire.extraConfig.pipewire = {
      "99-lowlatency" = {
        context = {
          properties.default.clock.min-quantum = cfg.quantum;
          modules = [
            {
              name = "libpipewire-module-rtkit";
              flags = ["ifexists" "nofail"];
              args = {
                nice.level = -15;
                rt = {
                  prio = 88;
                  time.soft = 200000;
                  time.hard = 200000;
                };
              };
            }
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                server.address = ["unix:native"];
                pulse.min = {
                  req = qr;
                  quantum = qr;
                  frag = qr;
                };
              };
            }
          ];

          stream.properties = {
            node.latency = qr;
            resample.quality = 1;
          };
        };
      };
    };

    environment.etc = {
      "wireplumber/main.lua.d/99-alsa-lowlatency.lua".text = ''
        alsa_monitor.rules = {
          {
            matches = {{{ "node.name", "matches", "alsa_output.*" }}};
            apply_properties = {
              ["audio.format"] = "S32LE",
              ["audio.rate"] = ${toString (cfg.rate * 2)},
              ["api.alsa.period-size"] = 2,
            },
          },
        }
      '';
    };
  };
}
