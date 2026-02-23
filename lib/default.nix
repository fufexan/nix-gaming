{inputs, ...}: let
  inherit (builtins) elem filter throw;
  inherit (inputs.nixpkgs.lib) warn hasPrefix hasSuffix filesystem optionalString assertOneOf;
in {
  flake.lib = {
    mkPatches = dir: excludes:
      map (e:
        if hasPrefix "/nix/store" e
        then e
        else /. + e)
      (builtins.filter
        (hasSuffix ".patch")
        (filter (e: !(elem e excludes)) (filesystem.listFilesRecursive dir)));

    legendaryBuilder = pkgs: {
      games ? {},
      opts ? {},
    }:
      builtins.attrValues (builtins.mapAttrs (
          name: value:
            pkgs.callPackage ../pkgs/legendary
            ({
                inherit (inputs.self.packages.${pkgs.stdenv.hostPlatform.system}) wine-discord-ipc-bridge;
                pname = name;
              }
              // opts
              // value)
        )
        games);

    mkDeprecated = variant: return: {
      target, # what to deprecate: "package" or "module"
      name, # name of the deprecated component
      instructions, # instructions to migrate away from the deprecated component
      repo ? "nix-gaming", # not likely to change, but just in case
      date ? "", # optionally allow supplying a date
    }: let
      optionalDate = optionalString (date != "") " as of ${date}";

      # constructed warning message
      message = assert assertOneOf "target" target ["package" "module"]; ''
        The ${target} ${name} in ${repo} has been deprecated${optionalDate}.

        ${instructions}
      '';
    in
      if variant == "warn"
      then warn message return
      else if variant == "throw"
      then throw message
      else
        # could this be asserted earlier?
        throw ''
          Unknown variant: ${variant}. Must be one of:
            - warn
            - throw
        '';
  };
}
