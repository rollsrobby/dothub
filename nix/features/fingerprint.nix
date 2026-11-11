{
  flake.nixosModules.fingerprint =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      fingerprintLidState = pkgs.writeShellScript "fingerprint-lid-state" ''
        set -eu

        set_fingerprint_authorized() {
          authorized="$1"

          for device in /sys/bus/usb/devices/*; do
            [ -r "$device/idVendor" ] || continue
            [ -r "$device/idProduct" ] || continue
            [ -w "$device/authorized" ] || continue

            if [ "$(cat "$device/idVendor")" = 27c6 ] && [ "$(cat "$device/idProduct")" = 609c ]; then
              echo "$authorized" > "$device/authorized"
            fi
          done
        }

        lid_state=unknown
        for state_file in /proc/acpi/button/lid/*/state; do
          [ -e "$state_file" ] || continue
          if ${pkgs.gnugrep}/bin/grep -qi closed "$state_file"; then
            lid_state=closed
            break
          elif ${pkgs.gnugrep}/bin/grep -qi open "$state_file"; then
            lid_state=open
          fi
        done

        if [ "$lid_state" != open ]; then
          if [ "$lid_state" = unknown ]; then
            echo "Unable to determine lid state; disabling fingerprint reader" >&2
          fi
          ${pkgs.systemd}/bin/systemctl stop fprintd.service
          set_fingerprint_authorized 0
        else
          set_fingerprint_authorized 1
          ${pkgs.systemd}/bin/systemctl start fprintd.service
        fi
      '';
    in
    {
      config = lib.mkMerge [
        { services.fprintd.enable = lib.mkDefault true; }
        (lib.mkIf config.services.fprintd.enable {
          services.acpid = {
            enable = true;
            handlers.lid = {
              event = "button/lid.*";
              action = "${fingerprintLidState}";
            };
          };

          services.fprintd = {
            tod.enable = true;
            tod.driver = pkgs.libfprint-2-tod1-goodix;
          };

          security.pam.services = {
            login.fprintAuth = true;
            sudo.fprintAuth = true;
            polkit-1.fprintAuth = true;
          };

          systemd.services.fingerprint-lid-state = {
            description = "Toggle fingerprint reader based on lid state";
            wantedBy = [ "multi-user.target" ];
            wants = [ "fprintd.service" ];
            after = [
              "acpid.service"
              "fprintd.service"
            ];
            before = [ "display-manager.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = fingerprintLidState;
            };
          };
        })
      ];
    };
}
