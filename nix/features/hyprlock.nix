{
  flake.nixosModules.hyprlock = {
    security.pam.services.hyprlock = { };
  };

  flake.homeModules.hyprlock = {
    programs.hyprlock = {
      enable = true;

      settings = {
        auth = {
          pam = {
            enabled = true;
          };
          fingerprint = {
            enabled = true;
            ready_message = "Touch the fingerprint sensor";
            present_message = "Scanning fingerprint...";
            retry_delay = 250; # in milliseconds
          };
        };

        background = [
          {
            monitor = "";
            path = "~/walls/nature/a_lake_with_trees_and_clouds.png";
            blur_passes = 2;
            # color = "rgba(11, 13, 18, 1.0)";
            contrast = 0.8916;
            brightness = 0.8172;
            vibrancy = 0.1696;
            vibrancy_darkness = 0.0;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "260, 46";
            outline_thickness = 2;
            dots_spacing = 0.2;
            dots_center = true;
            outer_color = "rgba(80, 88, 105, 1.0)";
            inner_color = "rgba(24, 28, 36, 1.0)";
            font_color = "rgba(234, 236, 242, 1.0)";
            fade_on_empty = true;
            placeholder_text = "Password";
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          {
            monitor = "";
            text = "$TIME";
            font_size = 72;
            color = "rgba(234, 236, 242, 1.0)";
            position = "0, 160";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "$FPRINTPROMPT";
            font_size = 12;
            color = "rgba(234, 236, 242, 1.0)";
            position = "0, -180";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "$FPRINTFAIL";
            font_size = 12;
            color = "rgba(224, 86, 86, 1.0)";
            position = "0, -205";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "Hi, $USER";
            color = "rgba(216, 222, 233, 0.70)";
            font_size = 14;
            position = "0, 10";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
