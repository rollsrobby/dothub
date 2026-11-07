{ inputs, lib, ... }:
let
  unfreePackages = [
    "1password"
    "1password-cli"
    "azure-storage-explorer"
    "corefonts"
    "libfprint-2-tod1-goodix"
    "microsoft-edge"
    "ngrok"
    "proton-pass"
    "spotify"
    "vscode"
  ];
  allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
in
{
  flake.nixosModules.unfree =
    { ... }:
    {
      nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;
    };
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = allowUnfreePredicate;
      };
    };
}
