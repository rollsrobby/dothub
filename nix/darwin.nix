{ lib, ... }:
{
  # Like nixosModules/homeModules, allow features to contribute named modules
  # from separate files instead of treating darwinModules as one unique value.
  options.flake.darwinModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
    description = "Reusable nix-darwin modules.";
  };
}
