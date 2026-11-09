{ inputs, self, ... }:
{
  flake.darwinConfigurations.rms-mbp = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      self.darwinModules.rmsMbp
      self.darwinModules.macApplications
      inputs.home-manager.darwinModules.home-manager
      inputs.mac-app-util.darwinModules.default
      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        # Keep the existing Mac profile separate from the Linux desktop profile.
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.rms = self.homeModules.rmsMbp;
          # Create application trampolines for Home Manager GUI packages too.
          sharedModules = [ inputs.mac-app-util.homeManagerModules.default ];
          backupFileExtension = "backup";
        };

        nix-homebrew = {
          enable = true;
          enableRosetta = false;
          user = "rms";
        };
      }
    ];
  };
}
