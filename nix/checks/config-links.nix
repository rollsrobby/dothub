{ self, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      linux = self.nixosConfigurations.rms-fw.config.home-manager.users.rms;
      mac = self.darwinConfigurations.rms-mbp.config.home-manager.users.rms;
      apps = [
        "nvim"
        "ghostty"
      ];
      correctLinks =
        home:
        lib.all (
          app:
          let
            link = home.xdg.configFile.${app};
          in
          link.enable
          && link.recursive
          && link.source == home.lib.file.mkOutOfStoreSymlink "${home.dotfiles.directory}/${app}"
          && home.home.file.${"${home.xdg.configHome}/${app}"}.enable
        ) apps;
    in
    {
      checks.config-links =
        assert linux.dotfiles.directory == "/home/rms/dotfiles";
        assert mac.dotfiles.directory == "/Users/rms/dotfiles";
        assert correctLinks linux && correctLinks mac;
        # Evaluate Darwin links above, but only build Linux derivations here.
        pkgs.runCommand "shared-config-links" { } ''
          test -L ${linux.xdg.configFile.nvim.source}
          test "$(readlink ${linux.xdg.configFile.nvim.source})" = /home/rms/dotfiles/nvim
          test -L ${linux.xdg.configFile.ghostty.source}
          test "$(readlink ${linux.xdg.configFile.ghostty.source})" = /home/rms/dotfiles/ghostty
          touch "$out"
        '';
    };
}
