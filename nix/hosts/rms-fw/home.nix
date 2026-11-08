{ self, ... }:
{
  flake.homeModules.rmsFw = {
    home.stateVersion = "25.05";

    imports = [
      self.homeModules.rmsFwSesh
      self.homeModules.packages
      self.homeModules.opencode
      self.homeModules.cli
      self.homeModules.fish
      self.homeModules.session
      self.homeModules.walker
      self.homeModules.waybar
      self.homeModules.hyprland
      self.homeModules.hyprlock
      self.homeModules.awww
      self.homeModules.hypridle
      self.homeModules.configLinks
      self.homeModules.ssh
      self.homeModules.cursor
      self.homeModules.rex
      self.homeModules.braveOrigin
      self.homeModules.redisTui
      self.homeModules.azureStorageExplorer
    ];
  };

}
