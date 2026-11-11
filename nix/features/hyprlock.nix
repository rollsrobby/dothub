{ lib, ... }:
let
  colors = (import ../../lib/desktop-colors.nix).greeter;
  colorFormats = import ../../lib/desktop-color-formats.nix { inherit lib; };
  opaque = color: colorFormats.hyprlock color "1.0";
  label = text: size: y: color: {
    monitor = "";
    inherit text;
    font_family = "Sans";
    font_size = size;
    color = opaque color;
    position = "0, ${toString y}";
    halign = "center";
    valign = "center";
  };
in
{
  flake.nixosModules.hyprlock = {
    security.pam.services.hyprlock = { };
  };

  flake.homeModules.hyprlock = { pkgs, lib, ... }: {
    programs.hyprlock = {
      enable = true;

      settings = {
        auth = {
          pam = {
            enabled = true;
          };
          fingerprint = {
            enabled = lib.mkDefault true;
            ready_message = "Touch the fingerprint sensor";
            present_message = "Scanning fingerprint...";
            retry_delay = 250; # in milliseconds
          };
        };

        general.grace = 0;

        background = [
          {
            monitor = "";
            path = "${./files/hyprlock/background-image.png}";
            blur_passes = 2;
            contrast = 0.8916;
            brightness = 0.8172;
            vibrancy = 0.1696;
            vibrancy_darkness = 0.0;
          }
        ];

        shape = [
          {
            monitor = "";
            size = "640, 260";
            position = "0, -65";
            halign = "center";
            valign = "center";
            rounding = 14;
            color = opaque colors.surface;
            border_color = opaque colors.border;
            border_size = 1;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "400, 52";
            outline_thickness = 1;
            rounding = 8;
            dots_spacing = 0.2;
            dots_center = true;
            outer_color = opaque colors.inputBorder;
            inner_color = opaque colors.input;
            font_color = opaque colors.text;
            check_color = opaque colors.focus;
            fail_color = opaque colors.danger;
            capslock_color = opaque colors.focus;
            font_family = "Sans";
            fade_on_empty = false;
            placeholder_text = "Password";
            fail_text = "Incorrect password — try again";
            position = "0, -65";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          (label "$TIME" 72 230 colors.text)
          (label "cmd[update:60000] ${pkgs.coreutils}/bin/date '+%A, %d %B'" 16 150 colors.focus)
          (label "Welcome back, $USER" 22 20 colors.text)
          # Keep both fingerprint lines inside the opaque panel, below the input.
          (label "$FPRINTPROMPT" 13 (-130) colors.focus)
          (label "$FPRINTFAIL" 12 (-160) colors.danger)
        ];
      };
    };
  };
}
