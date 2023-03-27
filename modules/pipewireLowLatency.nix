{
  config,
  lib,
  pkgs,
  ...
}:
# low-latency PipeWire configuration
# extends the nixpkgs module
let
  cfg = config.services.pipewire.lowLatency;
  qr = "${toString cfg.quantum}/${toString cfg.rate}";
  json = pkgs.formats.json {};
in {
  options = {
    services.pipewire.lowLatency = {
      enable = lib.mkEnableOption (lib.mdDoc "Enable low latency");

      quantum = lib.mkOption {
        description = lib.mdDoc "Minimum quantum to set";
        type = lib.types.int;
        default = 64;
        example = 32;
      };

      rate = lib.mkOption {
        description = lib.mdDoc "Rate to set";
        type = lib.types.int;
        default = 48000;
        example = 96000;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # pipewire native config
    environment.etc = {
      "pipewire/pipewire.d/99-lowlatency.conf".source = json.generate "99-lowlatency.conf" {
        context.properties.default.clock.min-quantum = cfg.quantum;
      };

      # pulse clients config
      "pipewire/pipewire-pulse.d/99-lowlatency.conf".source = json.generate "99-lowlatency.conf" {
        context.modules = [
          {
            name = "libpipewire-module-rtkit";
            args = {
              nice.level = -15;
              rt.prio = 88;
              rt.time.soft = 200000;
              rt.time.hard = 200000;
            };
            flags = ["ifexists" "nofail"];
          }
          {
            name = "libpipewire-module-protocol-pulse";
            args = {
              pulse.min.req = qr;
              pulse.min.quantum = qr;
              pulse.min.frag = qr;
              server.address = ["unix:native"];
            };
          }
        ];

        stream.properties = {
          node.latency = qr;
          resample.quality = 1;
        };
      };

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
