{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # Check formatting in the same source snapshot used to build the system.
      checks.formatting = pkgs.runCommand "nix-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
        cd ${self}
        find . -type f -name '*.nix' -print0 | xargs -0 nixfmt --check
        touch "$out"
      '';
    };
}
