{ self, ... }:
{
  flake.homeModules.rmsLab =
    { pkgs, ... }:
    {
      imports = [
        self.homeModules.cli
        self.homeModules.ssh
        self.homeModules.fish
        self.homeModules.opencode
        self.homeModules.rex
        self.homeModules.configLinks
      ];
      home.stateVersion = "26.05";
      home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.tree-sitter ];

      xdg.configFile.ghostty.enable = false;
    };
}
