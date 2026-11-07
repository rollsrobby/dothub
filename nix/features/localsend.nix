{
  flake.nixosModules.localsend =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        localsend
      ];

      programs.localsend.enable = true;
    };
}
