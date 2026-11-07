{
  flake.nixosModules.powerProfile =
    { pkgs, ... }:
    let
      automaticPowerProfile = pkgs.writeShellScript "automatic-power-profile" ''
        set -eu

        on_ac=0
        for supply in /sys/class/power_supply/*; do
          [ -r "$supply/type" ] || continue
          [ -r "$supply/online" ] || continue

          if [ "$(cat "$supply/type")" = Mains ] && [ "$(cat "$supply/online")" = 1 ]; then
            on_ac=1
            break
          fi
        done

        if [ "$on_ac" = 1 ]; then
          profile=performance
        else
          capacity=
          for supply in /sys/class/power_supply/*; do
            [ -r "$supply/type" ] || continue
            [ -r "$supply/capacity" ] || continue

            if [ "$(cat "$supply/type")" = Battery ]; then
              capacity="$(cat "$supply/capacity")"
              break
            fi
          done

          if [ -z "$capacity" ]; then
            echo "Unable to determine battery capacity" >&2
            exit 1
          elif [ "$capacity" -le 40 ]; then
            profile=power-saver
          else
            profile=balanced
          fi
        fi

        ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$profile"
      '';
    in
    {
      # Battery monitoring
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
      systemd.services.upower.wantedBy = [ "multi-user.target" ];

      services.udev.extraRules = ''
        SUBSYSTEM=="power_supply", ACTION=="change", TAG+="systemd", ENV{SYSTEMD_WANTS}+="automatic-power-profile.service"
      '';

      systemd.services.automatic-power-profile = {
        description = "Select power profile from AC state and battery level";
        wantedBy = [ "multi-user.target" ];
        wants = [ "power-profiles-daemon.service" ];
        after = [ "power-profiles-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = automaticPowerProfile;
        };
      };

    };
}
