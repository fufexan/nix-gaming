{ config, lib, ... }:

# low-latency PipeWire configuration
# extends the nixpkgs module

let
  cfg = config.services.pipewire.lowLatency;
in
{
  options = {
    services.pipewire.lowLatency = {
      enable = lib.mkEnableOption "Enable low latency";
      quantum = lib.mkOption {
        description = "Minimum quantum to set";
        type = lib.types.int;
        default = 64;
        example = 32;
      };
      rate = lib.mkOption {
        description = "Rate to set";
        type = lib.types.int;
        default = 48000;
        example = 96000;
      };
    };
  };

  config =
    let
      qr = "${toString cfg.quantum}/${toString cfg.rate}";
    in
    lib.mkIf cfg.enable {
      services.pipewire = {
        config = {
          # pipewire native config
          pipewire = {
            "context.properties" = { "default.clock.min-quantum" = cfg.quantum; };
          };

          # pulse clients config
          pipewire-pulse = {
            "context.properties" = { };
            "context.modules" = [
              {
                name = "libpipewire-module-rtkit";
                args = {
                  "nice.level" = -15;
                  "rt.prio" = 88;
                  "rt.time.soft" = 200000;
                  "rt.time.hard" = 200000;
                };
                flags = [ "ifexists" "nofail" ];
              }
              { name = "libpipewire-module-protocol-native"; }
              { name = "libpipewire-module-client-node"; }
              { name = "libpipewire-module-adapter"; }
              { name = "libpipewire-module-metadata"; }
              {
                name = "libpipewire-module-protocol-pulse";
                args = {
                  "pulse.min.req" = qr;
                  "pulse.min.quantum" = qr;
                  "pulse.min.frag" = qr;
                  "server.address" = [ "unix:native" ];
                };
              }
            ];

            "stream.properties" = {
              "node.latency" = qr;
              "resample.quality" = 1;
            };
          };
        };
        # lower latency alsa format
        media-session.config.alsa-monitor = {
          rules = [
            {
              matches = [{ node.name = "alsa_output.*"; }];
              actions = {
                update-props = {
                  "audio.format" = "S32LE";
                  "audio.rate" = cfg.rate * 2;
                  "api.alsa.period-size" = 2;
                };
              };
            }
          ];
        };
      };
    };
}
