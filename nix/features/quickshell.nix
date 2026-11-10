{
  flake.homeModules.quickshell =
    { pkgs, lib, ... }:
    let
      # Explicit command dependencies keep the VM prototype reproducible.
      commands = with pkgs; [
        bash
        coreutils
        curl
        gnused
        gnugrep
        jq
        procps
        systemd
        hyprland
        hyprlock
        hyprshutdown
        ghostty
        btop
        networkmanager
        wifitui
        bluetui
        bluez
        pavucontrol
        wireplumber
        power-profiles-daemon
        swaynotificationcenter
      ];
      launch = pkgs.writeShellScript "quickshell-bar" ''
        export PATH=${lib.makeBinPath commands}:$PATH
        exec ${pkgs.quickshell}/bin/qs --no-duplicate --config faithful
      '';
    in
    {
      home.packages = [ pkgs.quickshell ];
      xdg.configFile."quickshell/faithful".source = ./files/quickshell;

      # UWSM owns graphical-session.target; the bar exits with the desktop.
      systemd.user.services.quickshell = {
        Unit = {
          Description = "Quickshell bar (VM prototype)";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${launch}";
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
