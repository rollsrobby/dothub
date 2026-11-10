{ moduleWithSystem, ... }:
{
  # Opt-in preview: only the VM imports this module.
  flake.homeModules.vmHyprlock = moduleWithSystem (
    { config, ... }:
    { lib, pkgs, ... }:
    let
      colors = (import ../../lib/desktop-colors.nix).greeter;
      colorFormats = import ../../lib/desktop-color-formats.nix { inherit lib; };
      opaque = color: colorFormats.hyprlock color "1.0";
      background =
        pkgs.runCommand "vm-lock-background.png" { nativeBuildInputs = [ pkgs.imagemagick ]; }
          ''
            magick -size 1440x900 -define gradient:angle=135 \
              'gradient:#${colors.background}-#${colors.backgroundEnd}' "PNG:$out"
          '';
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
      home.packages = [
        (pkgs.writeShellApplication {
          name = "preview-lock";
          text = ''
            if [[ -z "''${WAYLAND_DISPLAY:-}" ]]; then
              echo "Run preview-lock from a terminal in the VM's Hyprland session." >&2
              exit 1
            fi
            exec ${config.packages.idle-policy}/bin/idle-policy lock
          '';
        })
      ];

      programs.hyprlock.settings = {
        auth.fingerprint.enabled = lib.mkForce false;
        general.grace = 0;
        background = lib.mkForce [
          {
            monitor = "";
            path = "${background}";
            color = opaque colors.background;
            blur_passes = 0;
          }
        ];
        shape = lib.mkForce [
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
        input-field = lib.mkForce [
          {
            monitor = "";
            size = "400, 52";
            position = "0, -65";
            halign = "center";
            valign = "center";
            rounding = 8;
            outline_thickness = 1;
            outer_color = opaque colors.inputBorder;
            inner_color = opaque colors.input;
            font_color = opaque colors.text;
            check_color = opaque colors.focus;
            fail_color = opaque (import ../../lib/desktop-colors.nix).lock.danger;
            font_family = "Sans";
            dots_center = true;
            dots_spacing = 0.2;
            fade_on_empty = false;
            placeholder_text = "Password";
            fail_text = "Incorrect password — try again";
            capslock_color = opaque colors.focus;
          }
        ];
        label = lib.mkForce [
          (label "$TIME" 72 230 colors.text)
          (label "cmd[update:60000] ${pkgs.coreutils}/bin/date '+%A, %d %B'" 16 150 colors.focus)
          (label "Welcome back, $USER" 22 20 colors.text)
          (label "Enter your password to unlock" 13 (-130) colors.focus)
          (label "VM preview  ·  rms / vm" 12 (-235) colors.focus)
        ];
      };
    }
  );
}
