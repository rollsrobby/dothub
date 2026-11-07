{
  flake.nixosModules._1password =
    { pkgs, ... }:
    {
      programs._1password.enable = true;
      programs._1password-gui.enable = true;

    };
}
