{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  # Only advertise platforms this configuration supports
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;
    };
}
