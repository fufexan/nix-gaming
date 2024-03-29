{
  inputs,
  self,
  ...
}: {
  flake.nixosModules = let
    inherit (inputs.nixpkgs.lib) filter attrNames;
  in {
    pipewireLowLatency = import ./pipewireLowLatency.nix;

    steamCompat = self.lib.mkDeprecated "warn" {} {
      name = "steamCompat";
      target = "module";
      instructions = ''
        `programs.steam.extraCompatPackages` is now available without
        the need of the steamCompat module. Please use the option
        provided by the nixpkgs module instead. See the relevant
        pull request for more details:

        <https://github.com/NixOS/nixpkgs/pull/293564>

        You may remove the steamCompat module to supress this message.
      '';
    };

    platformOptimizations = import ./platformOptimizations.nix;

    default = throw ''
      The usage of default module is deprecated as multiple modules are provided by nix-gaming. Please use
      the exact name of the module you would like to use. Available modules are:

      ${builtins.concatStringsSep "\n" (filter (name: name != "default") (attrNames inputs.self.nixosModules))}
    '';
  };
}
