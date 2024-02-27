{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.types) listOf package;
  inherit (lib.options) mkOption literalExpression;
  inherit (lib.strings) makeBinPath;

  cfg = config.programs.steam;
in {
  meta.maintainers = with lib.maintainers; [NotAShelf];

  options.programs.steam = {
    extraCompatPackages = mkOption {
      type = listOf package;
      default = [];
      defaultText = literalExpression "[]";
      example = literalExpression ''
        [
          pkgs.luxtorpeda
          inputs.nix-gaming.packages.$${pkgs.system}.proton-ge
        ]
      '';
      description = ''
        Extra packages to be used as compatibility tools for Steam on Linux. Added packages will be included
        in the `STEAM_EXTRA_COMPAT_TOOLS_PATHS` environmental variable. For more information see
        <https://github.com/ValveSoftware/steam-for-linux/issues/6310>.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Append the extra compatibility packages to whatever else the env variable was populated with.
    # For more information see https://github.com/ValveSoftware/steam-for-linux/issues/6310.
    environment.sessionVariables = mkIf (cfg.extraCompatPackages != []) {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = [
        (makeBinPath cfg.extraCompatPackages)
      ];
    };
  };
}
