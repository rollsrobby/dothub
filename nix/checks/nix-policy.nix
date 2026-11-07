{ self, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      linux = self.nixosConfigurations.rms-fw.config;
      mac = self.darwinConfigurations.rms-mbp.config;
      features = [
        "nix-command"
        "flakes"
      ];
    in
    {
      checks.nix-policy =
        assert lib.all
          (
            host:
            lib.all (feature: builtins.elem feature host.nix.settings.experimental-features) features
            && host.nix.gc.automatic
            && host.nix.gc.options == "--delete-older-than 30d"
          )
          [
            linux
            mac
          ];
        assert linux.nix.gc.dates == [ "weekly" ] && linux.nix.gc.persistent;
        assert linux.systemd.timers.nix-gc.timerConfig.OnCalendar == [ "weekly" ];
        assert linux.systemd.timers.nix-gc.timerConfig.Persistent;
        assert
          mac.nix.gc.interval == [
            {
              Weekday = 7;
              Day = null;
              Month = null;
              Hour = 3;
              Minute = 15;
            }
          ];
        assert mac.launchd.daemons.nix-gc.serviceConfig.StartCalendarInterval == mac.nix.gc.interval;
        assert !mac.launchd.daemons.nix-gc.serviceConfig.RunAtLoad;
        assert lib.hasInfix "--delete-older-than 30d" mac.launchd.daemons.nix-gc.command;
        pkgs.writeText "shared-nix-policy.json" (
          builtins.toJSON {
            experimentalFeatures = features;
            gcOptions = linux.nix.gc.options;
            linuxSchedule = linux.nix.gc.dates;
            macSchedule = mac.nix.gc.interval;
          }
        );
    };
}
