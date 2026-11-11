{
  flake.nixosModules.tailscale =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.tailscale.enable = lib.mkDefault true;

      systemd.user.services.tailscale-systray = lib.mkIf config.services.tailscale.enable {
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
