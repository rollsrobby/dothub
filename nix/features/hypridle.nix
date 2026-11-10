{ moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        idle-policy = pkgs.writeShellApplication {
          name = "idle-policy";
          runtimeInputs = [
            pkgs.python3
            pkgs.systemd
            pkgs.procps
            pkgs.hyprlock
          ];
          text = ''exec python3 ${./files/idle-policy/policy.py} "$@"'';
        };
      };
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        idle-policy = pkgs.runCommand "idle-policy-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          export PYTHONDONTWRITEBYTECODE=1
          python3 ${./files/idle-policy/test_policy.py} ${./files/idle-policy/policy.py}
          touch "$out"
        '';
      };
    };

  flake.homeModules.hypridle = moduleWithSystem (
    { config, pkgs, ... }:
    let
      policy = "${config.packages.idle-policy}/bin/idle-policy";
      dpms = "${pkgs.hyprland}/bin/hyprctl dispatch dpms";
    in
    {
      services.hypridle = {
        enable = true;
        package = pkgs.hypridle.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./files/idle-policy/hypridle-cancel-inhibited-retries.patch
          ];
        });
        settings = {
          general = {
            lock_cmd = "${policy} lock";
            before_sleep_cmd = "${policy} lock";
            after_sleep_cmd = "${dpms} on";
            # Wait for the compositor's lock confirmation, not just locker launch.
            inhibit_sleep = 3;
            on_lock_cmd = "${policy} locked";
            on_unlock_cmd = "${policy} unlocked";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "${policy} lock";
            }
            {
              timeout = 600;
              on-timeout = "${dpms} off";
              on-resume = "${dpms} on";
            }
            {
              timeout = 900;
              condition_cmd = "${policy} check-battery";
              condition_retry = 5;
              on-timeout = "${policy} suspend-battery";
            }
            {
              timeout = 1800;
              condition_cmd = "${policy} check-ac";
              condition_retry = 5;
              on-timeout = "${policy} suspend-ac";
            }
          ];
        };
      };

      # Never reuse a lock confirmation from a previous daemon/session.
      systemd.user.services.hypridle.Service.ExecStartPre = "${policy} reset";

      # Own lid handling only while Hypridle is running. If this process exits,
      # its inhibitor is released and logind resumes safe default lid handling.
      systemd.user.services.dock-lid-policy = {
        Unit = {
          Description = "AC-aware clamshell suspend policy";
          After = [ "hypridle.service" ];
          BindsTo = [ "hypridle.service" ];
          PartOf = [ "graphical-session.target" ];
          ConditionPathExistsGlob = "/proc/acpi/button/lid/*/state";
        };
        Service = {
          ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=handle-lid-switch --mode=block --who=dock-lid-policy --why=AC-aware-clamshell-policy ${policy} monitor-lid";
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "hypridle.service" ];
      };
    }
  );
}
