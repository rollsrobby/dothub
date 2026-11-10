{ moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        power-profile-policy =
          pkgs.runCommand "power-profile-policy-tests"
            {
              nativeBuildInputs = [
                pkgs.bash
                pkgs.coreutils
                pkgs.util-linux
                pkgs.jq
              ];
            }
            ''
              bash -euo pipefail ${./files/power-profile/test-policy.sh} ${./files/power-profile/policy.sh}
              touch "$out"
            '';
      };

      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        power-profile-policy = pkgs.writeShellApplication {
          name = "power-profile-policy";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.util-linux
            pkgs.jq
            pkgs.power-profiles-daemon
          ];
          text = builtins.readFile ./files/power-profile/policy.sh;
        };
      };
    };

  flake.nixosModules.powerProfile = {
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    systemd.services.upower.wantedBy = [ "multi-user.target" ];
  };

  flake.homeModules.powerProfile = moduleWithSystem (
    { config, ... }:
    let
      policy = "${config.packages.power-profile-policy}/bin/power-profile-policy";
    in
    {
      systemd.user.services.power-profile-session = {
        Unit = {
          Description = "Reset power-profile policy to Auto at graphical login";
          PartOf = [ "graphical-session.target" ];
          Before = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${policy} auto";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      systemd.user.services.power-profile-policy = {
        Unit = {
          Description = "Apply automatic power profile unless manually overridden";
          Requisite = [ "power-profile-session.service" ];
          After = [ "power-profile-session.service" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${policy} apply";
        };
      };

      # Polling also catches battery thresholds; udev SYSTEMD_WANTS is not a
      # reliable trigger for every change of an already-active power device.
      systemd.user.timers.power-profile-policy = {
        Unit = {
          Description = "Check AC and battery state every 30 seconds";
          PartOf = [ "graphical-session.target" ];
          After = [ "power-profile-session.service" ];
        };
        Timer = {
          OnActiveSec = "30s";
          OnUnitActiveSec = "30s";
          AccuracySec = "1s";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    }
  );
}
