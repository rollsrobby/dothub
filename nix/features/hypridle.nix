{
  flake.homeModules.hypridle =
    { pkgs, ... }:
    let
      suspendUnlessDocked = pkgs.writeShellScript "suspend-unless-docked" ''
        set -eu

        for status_file in /sys/class/drm/card*-*/status; do
          [ -r "$status_file" ] || continue

          connector="''${status_file%/status}"
          connector="''${connector##*/}"
          connector="''${connector#*-}"

          case "$connector" in
            eDP-*|LVDS-*) continue ;;
          esac

          if [ "$(cat "$status_file")" = connected ]; then
            ${pkgs.hyprland}/bin/hyprctl dispatch dpms off
            exit 0
          fi
        done

        ${pkgs.systemd}/bin/systemctl suspend
      '';
    in
    {
      services.hypridle = {
        enable = true;

        settings = {
          general = {
            lock_cmd = "pidof hyprlock >/dev/null || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };

          listener = [
            {
              timeout = 300;
              on-timeout = "pidof hyprlock >/dev/null || hyprlock";
            }
            {
              timeout = 900;
              on-timeout = "${suspendUnlessDocked}";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
}
