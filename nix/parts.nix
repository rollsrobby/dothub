{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  # Only advertise platforms this configuration supports. The systems input is
  # also used to constrain hunk's bun2nix dependency in flake.nix.
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;
    };
}
