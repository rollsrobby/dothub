{ lib, ... }:
let
  colors = (import ../../lib/desktop-colors.nix).greeter;
  colorFormats = import ../../lib/desktop-color-formats.nix { inherit lib; };
in
{
  flake.nixosModules.greeter = {
    services.displayManager.regreet = {
      enable = true;
      # Cage otherwise spans the combined monitor layout, which can center the
      # form between the external display and a still-enumerated laptop panel.
      # This is ReGreet's recommended single-output mode; "last" is not lid-aware.
      cageArgs = [
        "-s"
        "-d"
        "-m"
        "last"
      ];
      theme.name = "Adwaita-dark";
      extraCss = colorFormats.gtkDefinitions colors + builtins.readFile ./files/regreet/style.css;
      settings = {
        GTK.application_prefer_dark_theme = true;
        commands = {
          reboot = [
            "systemctl"
            "reboot"
          ];
          poweroff = [
            "systemctl"
            "poweroff"
          ];
        };
      };
    };

    # Keep greetd's existing login PAM stack and fingerprint/lid integration.
    services.greetd = {
      enable = true;
      useTextGreeter = false;
    };
  };
}
