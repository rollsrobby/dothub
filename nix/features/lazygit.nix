{
  flake.homeModules.lazygit = {
    programs.delta.enable = true;

    programs.lazygit = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        git.diffRenderers = [
          {
            name = "delta";
            type = "stdinFilter";
            colorArg = "always";
            command = "delta --dark --paging=never";
          }
        ];
      };
    };
  };
}
