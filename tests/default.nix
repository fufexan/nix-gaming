{
  config,
  inputs,
  lib,
  ...
}:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      callPackage = lib.callPackageWith (
        pkgs
        // {
          inherit (config.flake) nixosModules;
          inherit inputs;
        }
      );
    in
    {
      checks = {
        basic = callPackage ./checks/basic.nix { };
      };
      packages.test = self'.checks.basic.driverInteractive;
    };
}
