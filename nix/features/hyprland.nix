{ self, ... }:
{
  flake.nixosModules.hyprland =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.hyprlock
        self.nixosModules.greeter
      ];

      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        audio.enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        wireplumber = {
          enable = true;
          extraConfig."10-jabra-link-370" = {
            "monitor.alsa.rules" = [
              {
                matches = [
                  {
                    "node.name" = "alsa_output.usb-0b0e_Jabra_Link_370_70BF927E8921015700-00.analog-stereo";
                  }
                ];
                actions.update-props = {
                  "priority.session" = 20000;
                };
              }
              {
                matches = [
                  {
                    "node.name" = "alsa_input.usb-0b0e_Jabra_Link_370_70BF927E8921015700-00.mono-fallback";
                  }
                ];
                actions.update-props = {
                  "priority.session" = 20000;
                };
              }
            ];
          };
        };
      };

      programs.dconf.enable = true;
      services.gvfs.enable = true;
      services.udisks2.enable = true;

      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-hyprland
        ];
        config.common.default = [
          "hyprland"
          "gtk"
        ];
      };

      environment.systemPackages = with pkgs; [
        grim
        hyprpicker
        wl-clipboard
        wl-clipboard-x11
        slurp
        swappy
      ];
    };

  flake.homeModules.hyprland =
    { pkgs, ... }:
    let
      clamshellDisplay = pkgs.writeShellScriptBin "clamshell-display" ''
        set -eu

        internal_monitor=
        for connector in /sys/class/drm/card*-eDP-* /sys/class/drm/card*-LVDS-*; do
          [ -e "$connector" ] || continue
          connector_name="''${connector##*/}"
          internal_monitor="''${connector_name#*-}"
          break
        done

        if [ -z "$internal_monitor" ]; then
          echo "Unable to determine internal monitor" >&2
          exit 1
        fi

        lid_state=open
        for state_file in /proc/acpi/button/lid/*/state; do
          [ -e "$state_file" ] || continue
          if ${pkgs.gnugrep}/bin/grep -qi closed "$state_file"; then
            lid_state=closed
            break
          fi
        done

        if [ "$lid_state" = closed ]; then
          external_monitor="$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq --arg internal "$internal_monitor" -r '[.[] | select(.name != $internal)][0].name // empty')"
          if [ -z "$external_monitor" ]; then
            ${pkgs.hyprland}/bin/hyprctl eval "hl.monitor({ output = \"$internal_monitor\", disabled = false, mode = \"preferred\", position = \"auto\", scale = 1.33 })"
            exit 0
          fi

          for workspace in 1 2 3 4 5 6 7 8 9 10; do
            ${pkgs.hyprland}/bin/hyprctl dispatch moveworkspacetomonitor "$workspace" "$external_monitor" >/dev/null || true
          done

          ${pkgs.hyprland}/bin/hyprctl eval "hl.monitor({ output = \"$internal_monitor\", disabled = true })"
        else
          ${pkgs.hyprland}/bin/hyprctl eval "hl.monitor({ output = \"$internal_monitor\", disabled = false, mode = \"preferred\", position = \"auto\", scale = 1.33 })"
        fi
      '';
      clamshellMonitorEvents = pkgs.writeShellScriptBin "clamshell-monitor-events" ''
        set -eu

        if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          echo "HYPRLAND_INSTANCE_SIGNATURE is not set" >&2
          exit 1
        fi

        socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
        if [ ! -S "$socket" ]; then
          echo "Hyprland event socket is not available" >&2
          exit 1
        fi

        ${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$socket" - | while IFS= read -r event; do
          case "$event" in
            monitoradded*|monitorremoved*)
              ${pkgs.coreutils}/bin/sleep 1
              ${clamshellDisplay}/bin/clamshell-display
              ;;
          esac
        done
      '';
    in
    {
      home.packages = [
        clamshellDisplay
        clamshellMonitorEvents
      ];

      systemd.user.services.hyprpolkitagent = {
        Unit = {
          Description = "Hyprland polkit agent";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      systemd.user.services.clamshell-monitor-events = {
        Unit = {
          Description = "Monitor Hyprland display connection events";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${clamshellMonitorEvents}/bin/clamshell-monitor-events";
          Restart = "always";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      wayland.windowManager.hyprland = {
        enable = true;
        package = null;
        portalPackage = null;
        systemd.enable = false;
        configType = "lua";
      };

      xdg.configFile."hypr/hyprland.lua" = {
        source = ./files/hyprland/hyprland.lua;
      };
    };
}
