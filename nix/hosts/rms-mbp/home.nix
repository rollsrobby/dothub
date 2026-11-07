{ self, ... }:
{
  flake.homeModules.rmsMbp =
    { config, ... }:
    {
      imports = [
        self.homeModules.rmsMbpSesh
        self.homeModules.cli
        self.homeModules.configLinks
        self.homeModules.macCliPackages
        self.homeModules.macApplications
      ];

      home = {
        username = "rms";
        homeDirectory = "/Users/rms";
        stateVersion = "25.05";
        sessionPath = [ "$HOME/.dotnet/tools" ];

        # Keep editable application configuration in the external dotfiles checkout.
        # In particular, nix-darwin is linked as data, not imported as a module.
        file = {
          ".config/aerospace".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/aerospace";
          ".config/nix-darwin".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nix-darwin";
        };
      };

      programs.home-manager.enable = true;
    };
}
