{ self, ... }:
{
  flake.homeModules.rmsLab =
    { config, pkgs, ... }:
    {
      imports = [
        self.homeModules.cli
        self.homeModules.fish
        self.homeModules.opencode
        self.homeModules.rex
        self.homeModules.configLinks
      ];
      home.stateVersion = "26.05";
      home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.tree-sitter ];

      # Keep the editable Neovim configuration, without a desktop terminal link.
      xdg.configFile.ghostty.enable = false;
      programs.ssh = {
        enableDefaultConfig = false;
        settings."github.com" = {
          Hostname = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };
      };
      programs.sesh.settings.session = [
        {
          name = "dothub";
          path = "${config.home.homeDirectory}/dothub";
          startup_command = "nvim";
        }
      ];
    };
}
