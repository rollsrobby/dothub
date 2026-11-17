{ lib, ... }:
{
  # Allow separate hosts to contribute named Disko configurations.
  options.flake.diskoConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Named Disko configurations.";
  };
}
