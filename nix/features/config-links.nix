{
  flake.homeModules.configLinks =
    { config, lib, ... }:
    {
      options.dotfiles.directory = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/dotfiles";
        description = "Absolute path to the editable, out-of-store dotfiles checkout.";
      };

      config.xdg.configFile."nvim" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.directory}/nvim";
        recursive = true;
      };

      config.xdg.configFile."ghostty" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.directory}/ghostty";
        recursive = true;
      };
    };
}
