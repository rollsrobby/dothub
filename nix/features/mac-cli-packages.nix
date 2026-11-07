{
  flake.homeModules.macCliPackages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Linux uses Podman's docker-compatible command instead of this backend.
        colima
        docker
        # Darwin's native-process compatibility bundle; Linux's core system owns procps.
        procps
        # Linux's dedicated 1Password module owns this package and its integration.
        _1password-cli
      ];
    };
}
