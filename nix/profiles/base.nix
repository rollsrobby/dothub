{ self, ... }:
{
  flake.nixosModules.base = {
    imports = [
      self.nixosModules.nixPolicy
      self.nixosModules.fonts
      self.nixosModules.zsh
      self.nixosModules.fish
      self.nixosModules.keyboard
    ];
  };
}
