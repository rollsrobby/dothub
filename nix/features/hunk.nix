{ inputs, ... }:
{
  flake.homeModules.hunk = {
    imports = [
      inputs.hunk.homeManagerModules.default
    ];

    programs.hunk = {
      enable = true;
      enableGitIntegration = true; # Optional: set hunk as default git pager
      settings = {
        theme = "graphite";
        mode = "split";
        line_numbers = true;
      };
    };
  };
}
