{inputs, ...}: {
  flake.nixosModules = let
    inherit (inputs.nixpkgs.lib) filter attrNames;
  in {
    pipewireLowLatency = import ./pipewireLowLatency.nix;

    steamCompat = throw ''
      nix-gaming.nixosModules.steamCompat is deprecated as of 2024-03-12 due to the addition of
      `programs.steam.extraCompatPackages` to nixpkgs.

      See https://github.com/NixOS/nixpkgs/pull/293564 for more details. You may remove the steamCompat
      module to supress this message.
    '';

    default = throw ''
      The usage of default module is deprecated as multiple modules are provided by nix-gaming. Please use
      the exact name of the module you would like to use. Available modules are:

      ${builtins.concatStringsSep "\n" (filter (name: name != "default") (attrNames inputs.self.nixosModules))}
    '';
  };
}
