{
  flake.homeModules.session =
    { pkgs, lib, ... }:
    let
      colors = (import ../../lib/desktop-colors.nix).notifications;
      colorFormats = import ../../lib/desktop-color-formats.nix { inherit lib; };
      cssTokens = lib.mapAttrs (_: colorFormats.css) colors // {
        surfaceRgb = colorFormats.rgb colors.surface;
      };
    in
    {
      home.sessionPath = [
        "$HOME/.dotnet/tools"
      ];

      gtk = {
        enable = true;
        gtk4.theme = null;
        iconTheme = {
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
        };
      };

      services.cliphist = {
        enable = true;
        allowImages = true;
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "zen.desktop";
          "x-scheme-handler/http" = "zen.desktop";
          "x-scheme-handler/https" = "zen.desktop";
          "x-scheme-handler/about" = "zen.desktop";
          "x-scheme-handler/unknown" = "zen.desktop";
        };
        # Keep in case we want to switch back
        # defaultApplications = {
        #   "text/html" = "brave-origin.desktop";
        #   "x-scheme-handler/http" = "brave-origin.desktop";
        #   "x-scheme-handler/https" = "brave-origin.desktop";
        #   "x-scheme-handler/about" = "brave-origin.desktop";
        #   "x-scheme-handler/unknown" = "brave-origin.desktop";
        # };
      };

      # One notification daemon owns both popups and session notification history.
      services.swaync = {
        enable = true;
        settings = {
          positionX = "right";
          positionY = "top";
          layer = "overlay";
          control-center-layer = "overlay";
          cssPriority = "user";
          notification-window-width = 360;
          control-center-width = 420;
          control-center-margin-top = 12;
          control-center-margin-bottom = 12;
          control-center-margin-right = 12;
          timeout = 6;
          timeout-low = 4;
          timeout-critical = 0;
          notification-grouping = true;
          hide-on-clear = false;
          widgets = [
            "title"
            "dnd"
            "notifications"
          ];
          widget-config = {
            title = {
              text = "Notifications";
              clear-all-button = true;
              button-text = "Clear all";
            };
            dnd.text = "Do Not Disturb";
          };
        };
        style = lib.replaceStrings (map (name: "@${name}@") (
          builtins.attrNames cssTokens
        )) (builtins.attrValues cssTokens) (builtins.readFile ./files/swaync/style.css);
      };
    };
}
