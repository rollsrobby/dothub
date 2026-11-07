{
  flake.nixosModules.opencodeServer =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.opencodeServer;
      home = config.users.users.${cfg.user}.home;
      tailscale = "${pkgs.tailscale}/bin/tailscale --socket=/run/tailscale-opencode/tailscaled.sock";
      startServer = pkgs.writeShellScript "opencode-server" ''
        set -eu
        umask 077
        # Keep authentication stable across restarts, outside the public Nix store.
        if [ ! -s "$STATE_DIRECTORY/password" ]; then
          ${pkgs.openssl}/bin/openssl rand -hex 32 > "$STATE_DIRECTORY/password"
        fi
        export OPENCODE_PASSWORD="$(cat "$STATE_DIRECTORY/password")"
        exec ${cfg.package}/bin/opencode serve --hostname 127.0.0.1 --port ${toString cfg.port}
      '';
    in
    {
      options.services.opencodeServer = {
        enable = lib.mkEnableOption "the tailnet-only OpenCode web server";
        package = lib.mkPackageOption pkgs "opencode" { };
        user = lib.mkOption {
          type = lib.types.str;
          default = "rms";
          description = "Existing user whose projects and OpenCode configuration the server uses.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 4096;
          description = "Loopback-only OpenCode HTTP port.";
        };
      };

      config = lib.mkIf cfg.enable {
        # This is a foreground standalone server, not a second managed CLI service.
        systemd.services.opencode-server = {
          description = "OpenCode API and web UI";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          environment = {
            HOME = home;
            # Tools launched by agents need the same installed programs as the user.
            PATH = lib.mkForce "${home}/.nix-profile/bin:/etc/profiles/per-user/${cfg.user}/bin:/run/current-system/sw/bin";
          };
          serviceConfig = {
            User = cfg.user;
            WorkingDirectory = home;
            StateDirectory = "opencode-server";
            StateDirectoryMode = "0700";
            UMask = "0077";
            ExecStart = startServer;
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        # A separate identity provides opencode.<tailnet>.ts.net without renaming
        # the laptop. Userspace networking needs neither a TUN device nor routes.
        systemd.services.tailscale-opencode = {
          description = "Dedicated Tailscale identity for OpenCode";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            DynamicUser = true;
            StateDirectory = "tailscale-opencode";
            StateDirectoryMode = "0700";
            RuntimeDirectory = "tailscale-opencode";
            RuntimeDirectoryMode = "0700";
            ExecStart = "${pkgs.tailscale}/bin/tailscaled --tun=userspace-networking --statedir=/var/lib/tailscale-opencode --socket=/run/tailscale-opencode/tailscaled.sock --port=0";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        # Foreground Serve retries until the separate node is enrolled. No Funnel:
        # the HTTPS endpoint remains private and subject to the tailnet's ACLs.
        systemd.services.opencode-serve = {
          description = "Tailnet HTTPS proxy for OpenCode";
          wantedBy = [ "multi-user.target" ];
          requires = [ "tailscale-opencode.service" ];
          wants = [ "opencode-server.service" ];
          after = [
            "tailscale-opencode.service"
            "opencode-server.service"
          ];
          serviceConfig = {
            ExecStart = "${tailscale} serve --https=443 --bg=false http://127.0.0.1:${toString cfg.port}";
            Restart = "always";
            RestartSec = 10;
          };
        };
      };
    };
}
