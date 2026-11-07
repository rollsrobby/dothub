{
  flake.homeModules.opencode = {
    programs.opencode = {
      enable = true;

      # Keep shared preferences declarative rather than saving changes from the TUI.
      mutableSettings = false;

      commands = ./files/opencode/commands;
      agents = ./files/opencode/agents;

      settings = {
        permissions = [
          {
            action = "external_directory";
            resource = "~/.coding-agent/**";
            effect = "allow";
          }
        ];
        lsp = true;
        formatter = true;
        mcp.servers = {
          nixos = {
            type = "local";
            command = [ "mcp-nixos" ];
            disabled = true;
          };
          intlayer = {
            type = "local";
            command = [
              "npx"
              "-y"
              "@intlayer/mcp"
            ];
            disabled = true;
          };
          superlogical = {
            type = "remote";
            url = "https://www.superlogical.com/rex/community-mcp";
          };
        };
        plugins = [ "@slkiser/opencode-quota" ];
      };

      cli = {
        theme.name = "tokyonight";
        diffs = {
          wrap = "word";
          view = "auto";
          tree = true;
          single = false;
        };
        prompt.editor = true;
        session = {
          sidebar = "auto";
          scrollbar = false;
          thinking = "show";
          markdown = "rendered";
          verbosity = "high";
          image_preview = false;
          tps = true;
          permissions = "prompt";
        };
        animations = true;
        tabs = {
          mode = "off";
          scope = "cwd";
          layout = "horizontal";
          indicators = "status";
        };
      };
    };
  };
}
