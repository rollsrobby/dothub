{ inputs, ... }:
{
  flake.homeModules.walker =
    { pkgs, ... }:
    let
      copyCurrentDateTime = pkgs.writeShellApplication {
        name = "copy-current-date-time";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.wl-clipboard
        ];
        text = ''
          date '+%d.%m.%Y %H:%M:%S' | wl-copy --trim-newline
        '';
      };
    in
    {
      imports = [
        inputs.walker.homeManagerModules.default
      ];

      xdg.configFile."elephant/websearch.toml".text = ''
        [[entries]]
        default = true
        name = "DuckDuckGo"
        url = "https://duckduckgo.com/?q=%TERM%"
      '';

      xdg.desktopEntries.copy-current-date-time = {
        name = "Copy current date/time";
        comment = "Copy the current date and time to the clipboard";
        exec = "${copyCurrentDateTime}/bin/copy-current-date-time";
        icon = "appointment-new";
        terminal = false;
        categories = [ "Utility" ];
      };

      programs.walker = {
        enable = true;
        runAsService = true;
        config = {
          hide_quick_activation = true;
          hide_action_hints = true;
          hide_return_action = true;
          # entries = {
          #   text = "test";
          #   keywords = [
          #     "color"
          #     "picker"
          #     "hypr"
          #   ];
          #   actions = {
          #     "cp_use" = "date '+%d.%m.%Y %H:%M:%S' | wl-copy --trim-newline";
          #   };
          #   icon = "color-picker";
          # };
          keybinds = {
            next = [
              "Down"
              "ctrl j"
              "ctrl n"
            ];
            previous = [
              "Up"
              "ctrl k"
              "ctrl p"
            ];
            start = [
              "Return"
              "ctrl y"
            ];
            close = [
              "Escape"
              "ctrl c"
            ];
          };

          providers.actions = {
            desktopapplications = [
              {
                action = "pin";
                unset = true;
              }
              {
                action = "unpin";
                unset = true;
              }
              {
                action = "pinup";
                unset = true;
              }
              {
                action = "pindown";
                unset = true;
              }
            ];
          };
        };
      };
    };
}
