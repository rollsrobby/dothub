{
  flake.nixosModules.tailscale =
    { pkgs, ... }:
    {
      services.tailscale.enable = true;

      systemd.user.services.tailscale-systray = {
        description = "Tailscale system tray";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.tailscale}/bin/tailscale systray";
          Restart = "on-failure";
        };
      };
    };
}
