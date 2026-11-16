{ inputs, moduleWithSystem, ... }:
{
  flake.homeModules.rexRune = moduleWithSystem (
    { self', ... }:
    {
      home.packages = [ self'.packages.rex-rune ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.rex-rune = inputs.rex-rune.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
}
