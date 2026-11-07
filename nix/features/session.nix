{
  flake.homeModules.session =
    { pkgs, ... }:
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
          "text/html" = "brave-origin.desktop";
          "x-scheme-handler/http" = "brave-origin.desktop";
          "x-scheme-handler/https" = "brave-origin.desktop";
          "x-scheme-handler/about" = "brave-origin.desktop";
          "x-scheme-handler/unknown" = "brave-origin.desktop";
        };
      };

      services.dunst = {
        enable = true;
        iconTheme = {
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
          size = "32x32";
        };
        settings = {
          global = {
            icon_position = "left";
            follow = "mouse";
            width = 360;
            height = 160;
            offset = "24x24";
            origin = "top-right";
            notification_limit = 8;
            progress_bar = true;
            frame_width = 2;
            frame_color = "#08b4ff";
            separator_color = "frame";
            corner_radius = 8;
            padding = 16;
            horizontal_padding = 16;
            gap_size = 8;
            markup = "full";
            format = "<b>%s</b>\\n%b";
          };

          urgency_low = {
            background = "#111827";
            foreground = "#d1d5db";
            timeout = 4;
          };

          urgency_normal = {
            background = "#0f172a";
            foreground = "#e2e8f0";
            timeout = 6;
          };

          urgency_critical = {
            background = "#3f1d2e";
            foreground = "#f8fafc";
            frame_color = "#fb7185";
            timeout = 0;
          };
        };
      };
    };
}
