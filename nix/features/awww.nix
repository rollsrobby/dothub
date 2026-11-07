{
  flake.homeModules.awww =
    { config, pkgs, ... }:
    let
      wallpaperDir = "${config.home.homeDirectory}/walls";
      setRandomWallpaper = pkgs.writeShellScript "set-random-wallpaper" ''
        set -eu

        [ -d ${pkgs.lib.escapeShellArg wallpaperDir} ] || exit 0

        image="$(${pkgs.findutils}/bin/find ${pkgs.lib.escapeShellArg wallpaperDir} -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print | ${pkgs.coreutils}/bin/shuf -n 1)"
        [ -n "$image" ] || exit 0

        attempts=0
        until ${pkgs.awww}/bin/awww img "$image"; do
          attempts=$((attempts + 1))
          [ "$attempts" -lt 20 ] || exit 1
          ${pkgs.coreutils}/bin/sleep 0.25
        done
      '';
    in
    {
      home.packages = [ pkgs.awww ];

      systemd.user.services.awww-daemon = {
        Unit = {
          Description = "Wayland wallpaper daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${pkgs.awww}/bin/awww-daemon";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      systemd.user.services.awww-wallpaper-init = {
        Unit = {
          Description = "Initial wallpaper load";
          PartOf = [ "graphical-session.target" ];
          After = [ "awww-daemon.service" ];
          Requires = [ "awww-daemon.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = setRandomWallpaper;
        };
        Install = {
          WantedBy = [ "awww-daemon.service" ];
        };
      };

      systemd.user.services.awww-wallpaper-change = {
        Unit = {
          Description = "Change wallpaper randomly";
          PartOf = [ "graphical-session.target" ];
          After = [ "awww-daemon.service" ];
          Requires = [ "awww-daemon.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = setRandomWallpaper;
        };
      };

      systemd.user.timers.awww-wallpaper-change = {
        Unit = {
          Description = "Change wallpaper every 10 minutes";
          PartOf = [ "graphical-session.target" ];
        };
        Timer = {
          OnActiveSec = "10min";
          OnUnitActiveSec = "10min";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
