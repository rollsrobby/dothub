{ moduleWithSystem, ... }:
{
  flake.homeModules.waybar = moduleWithSystem (
    { pkgs, config, ... }:
    let
      ghostty = "${pkgs.ghostty}/bin/ghostty";
      btop = "${pkgs.btop}/bin/btop";
      hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
      nmtui = "${pkgs.networkmanager}/bin/nmtui";
      wifitui = "${pkgs.wifitui}/bin/wifitui";
      bluetui = "${pkgs.bluetui}/bin/bluetui";
      pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
      wpctl = "${pkgs.wireplumber}/bin/wpctl";
      hyprshutdown = "${pkgs.hyprshutdown}/bin/hyprshutdown";
      # Run outside Waybar's cgroup so closing the session cannot kill the power action.
      powerAction =
        action: label:
        "${pkgs.systemd}/bin/systemd-run --user --collect "
        + "--unit=waybar-power-action -- ${hyprshutdown} --no-fork "
        + "-t '${label}' --post-cmd '${pkgs.systemd}/bin/systemctl ${action}'";
      powerPolicy = "${config.packages.power-profile-policy}/bin/power-profile-policy";
      powerMenuActions = {
        automatic = "${powerPolicy} auto";
        "power-saver" = "${powerPolicy} power-saver";
        balanced = "${powerPolicy} balanced";
        performance = "${powerPolicy} performance";
      };
      showFailedUnits = pkgs.writeShellScript "show-failed-units" ''
        set -u

        show_failures() {
          scope="$1"
          shift

          echo "$scope units"
          "$@" --failed --no-pager

          while read -r unit _; do
            [ -n "$unit" ] || continue
            echo
            "$@" status "$unit" --no-pager || true
            if [ "$scope" = User ]; then
              ${pkgs.systemd}/bin/journalctl --user -b -u "$unit" -n 50 --no-pager
            else
              ${pkgs.systemd}/bin/journalctl -b -u "$unit" -n 50 --no-pager
            fi
          done < <("$@" --failed --no-legend --plain)
        }

        show_failures System ${pkgs.systemd}/bin/systemctl
        echo
        show_failures User ${pkgs.systemd}/bin/systemctl --user
        echo
        read -r -p "Press Enter to close..." _
      '';
      toggleBluetooth = pkgs.writeShellScript "toggle-bluetooth" ''
        set -eu

        if ${pkgs.bluez}/bin/bluetoothctl show | ${pkgs.gnugrep}/bin/grep -q "Powered: yes"; then
          ${pkgs.bluez}/bin/bluetoothctl power off
        else
          ${pkgs.bluez}/bin/bluetoothctl power on
        fi
      '';

      waybarSettings = [
        {
          reload_style_on_change = true;
          layer = "top";
          position = "top";
          spacing = 0;
          height = 45;
          "modules-left" = [
            "custom/nixos"
            "hyprland/workspaces"
          ];
          "modules-center" = [
            "privacy"
            "clock"
            "custom/weather"
          ];
          "modules-right" = [
            "group/system-monitor"
            "group/connections"
            "systemd-failed-units"
            "idle_inhibitor"
            "custom/dunst"
            "group/tray-expander"
          ];

          "custom/nixos" = {
            format = "";
            tooltip = false;
            menu = "on-click";
            menu-file = "~/.config/waybar/power_menu.xml";
            menu-actions = {
              shutdown = powerAction "poweroff" "Shutting down...";
              reboot = powerAction "reboot" "Restarting...";
              suspend = "${pkgs.systemd}/bin/systemctl suspend";
              lock = "${pkgs.procps}/bin/pidof hyprlock >/dev/null || ${hyprlock}";
            };
          };

          "custom/dunst" = {
            exec = "~/.config/waybar/scripts/dunst.sh";
            on-click = "${pkgs.dunst}/bin/dunstctl set-paused toggle";
            on-click-right = "${pkgs.dunst}/bin/dunstctl history-pop";
            tooltip-format = "Notifications\nClick: pause/resume\nRight-click: reopen latest notification";
            interval = 1;
          };

          "custom/weather" = {
            exec = "~/.config/waybar/scripts/get_weather.sh";
            signal = 8;
            on-click = "${pkgs.procps}/bin/pkill -RTMIN+8 waybar";
            return-type = "json";
            format = "{}";
            tooltip = true;
            interval = 900;
          };

          privacy = {
            icon-spacing = 8;
            icon-size = 18;
            transition-duration = 250;
            modules = [
              {
                type = "screenshare";
                tooltip = true;
                tooltip-icon-size = 24;
              }
              {
                type = "audio-in";
                tooltip = true;
                tooltip-icon-size = 24;
              }
            ];
            ignore-monitor = true;
          };

          "hyprland/workspaces" = {
            on-click = "activate";
            format = "{icon}";
            format-icons = {
              default = "";
              active = "󱓻";
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "0";
            };
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
              "6" = [ ];
              "7" = [ ];
              "8" = [ ];
            };
          };

          cpu = {
            interval = 5;
            format = "CPU {usage}%";
            tooltip-format = "CPU: {usage}%\nLoad: {load}";
            on-click = "${ghostty} -e ${btop}";
            on-click-right = ghostty;
          };

          memory = {
            interval = 10;
            format = "RAM {percentage}%";
            tooltip-format = "Memory: {used:0.1f}/{total:0.1f} GiB ({percentage}%)\nZram: {swapUsed:0.1f}/{swapTotal:0.1f} GiB ({swapPercentage}%)";
            on-click = "${ghostty} -e ${btop}";
            states = {
              warning = 80;
              critical = 90;
            };
          };

          # Stable controls: scroll audio to adjust volume, click for the mixer.
          "group/connections" = {
            orientation = "inherit";
            modules = [
              "network"
              "bluetooth"
              "pulseaudio"
              "custom/power-profile"
              "battery"
            ];
          };

          "group/system-monitor" = {
            orientation = "inherit";
            # Keep metrics stationary and clickable; no hover-to-reveal drawer.
            modules = [
              "cpu"
              "memory"
            ];
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
            timeout = 120;
            tooltip-format-activated = "Idle inhibition active (click to disable)";
            tooltip-format-deactivated = "Idle inhibition inactive (click to enable for up to 2 hours)";
          };

          systemd-failed-units = {
            hide-on-ok = true;
            format = " {nr_failed}";
            system = true;
            user = true;
            on-click = "${ghostty} --title=failed-units -e ${showFailedUnits}";
          };

          clock = {
            format = "<span weight='normal'>{0:L%a %b %d}</span>  <b>{0:%H:%M}</b>";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              format = {
                today = "<span color='#0db9d7'><b>{}</b></span>";
              };
            };
          };

          network = {
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format-wifi = "{icon} Wi-Fi";
            format-ethernet = "󰀂 LAN";
            format-disconnected = "󰤮";
            tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-disconnected = "Disconnected";
            interval = 3;
            spacing = 1;
            on-click = "${ghostty} --title=wifitui -e ${wifitui}";
            on-click-right = "${ghostty} -e ${nmtui}";
          };

          # Read the actual daemon profile plus the session's policy mode.
          "custom/power-profile" = {
            exec = "${powerPolicy} status";
            return-type = "json";
            interval = 2;
            menu = "on-click";
            menu-file = "~/.config/waybar/power_profile_menu.xml";
            menu-actions = powerMenuActions;
          };

          battery = {
            format = "{icon} {capacity}%";
            format-discharging = "{icon} {capacity}%";
            format-charging = "{icon} {capacity}%";
            format-plugged = " {capacity}%";
            format-icons = {
              charging = [
                "󰢜"
                "󰂆"
                "󰂇"
                "󰂈"
                "󰢝"
                "󰂉"
                "󰢞"
                "󰂊"
                "󰂋"
                "󰂅"
              ];
              default = [
                "󰁺"
                "󰁻"
                "󰁼"
                "󰁽"
                "󰁾"
                "󰁿"
                "󰂀"
                "󰂁"
                "󰂂"
                "󰁹"
              ];
            };
            format-full = "󰂅 {capacity}%";
            tooltip-format = "Battery: {capacity}% · {timeTo}\nClick to choose a power profile";
            tooltip-format-discharging = "Discharging: {capacity}%\nEstimated remaining: {time} · {power:0.1f} W\nClick to choose a power profile";
            tooltip-format-charging = "Charging: {capacity}%\nEstimated time to full: {time} · {power:0.1f} W\nClick to choose a power profile";
            tooltip-format-full = "Battery: {capacity}% · {timeTo}\nConfigured charge target reached\nClick to choose a power profile";
            interval = 5;
            full-at = 80;
            menu = "on-click";
            menu-file = "~/.config/waybar/power_profile_menu.xml";
            menu-actions = powerMenuActions;
            states = {
              warning = 30;
              critical = 15;
            };
          };

          "custom/bluetooth-settings" = {
            format = "";
            tooltip-format = "Bluetooth devices";
            on-click = "${ghostty} --title=bluetui -e ${bluetui}";
            on-click-right = toggleBluetooth;
          };

          bluetooth = {
            format = "";
            format-off = "";
            format-disabled = "";
            format-connected = "󰂱";
            format-no-controller = "";
            tooltip-format = "Devices connected: {num_connections}";
            on-click = "${ghostty} --title=bluetui -e ${bluetui}";
            on-click-right = toggleBluetooth;
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            on-click = "${pavucontrol}";
            on-click-right = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
            tooltip-format = "Playing at {volume}%";
            scroll-step = 5;
            format-muted = "";
            format-icons = {
              headphone = "";
              headset = "";
              default = [
                ""
                ""
                ""
              ];
            };
          };

          "group/tray-expander" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 200;
              children-class = "tray-group-item";
              click-to-reveal = true;
            };
            modules = [
              "custom/expand-icon"
              "custom/bluetooth-settings"
              "tray"
            ];
          };

          "custom/expand-icon" = {
            format = "󰍜";
            tooltip-format = "Click to show/hide Bluetooth and tray";
          };

          tray = {
            icon-size = 16;
            # CSS gives every app icon the same padded slot as the drawer controls.
            spacing = 0;
          };
        }
      ];

      waybarStyle = builtins.readFile ./files/waybar/waybar.css;
    in
    {
      programs.waybar = {
        enable = true;
        package = pkgs.waybar.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./files/waybar/waybar-hyprland-lua.patch
            ./files/waybar/waybar-systemd-refresh.patch
          ];
          # Exercise the patched update method with lightweight GTK/fmt stand-ins.
          postPatch = (old.postPatch or "") + ''
            sed -n '/auto SystemdFailedUnits::update() -> void/,$p' \
              src/modules/systemd_failed_units.cpp > "$TMPDIR/systemd-update.inc"
            $CXX -std=c++17 -I"$TMPDIR" \
              ${./files/waybar/tests/systemd-refresh.cpp} -o "$TMPDIR/test-systemd-refresh"
            "$TMPDIR/test-systemd-refresh"
          '';
        });
        systemd.enable = true;
        settings = waybarSettings;
        style = waybarStyle;
      };

      xdg.configFile."waybar/power_profile_menu.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <interface>
          <object class="GtkMenu" id="menu">
            <child>
              <object class="GtkMenuItem" id="automatic">
                <property name="label">Automatic</property>
              </object>
            </child>
            <child>
              <object class="GtkMenuItem" id="power-saver">
                <property name="label">Power Saver</property>
              </object>
            </child>
            <child>
              <object class="GtkMenuItem" id="balanced">
                <property name="label">Balanced</property>
              </object>
            </child>
            <child>
              <object class="GtkMenuItem" id="performance">
                <property name="label">Performance</property>
              </object>
            </child>
          </object>
        </interface>
      '';

      xdg.configFile."waybar/power_menu.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <interface>
            <object class="GtkMenu" id="menu">
                <child>
                    <object class="GtkMenuItem" id="lock">
                        <property name="label">Lock</property>
                    </object>
                </child>
                <child>
                    <object class="GtkMenuItem" id="suspend">
                        <property name="label">Suspend</property>
                    </object>
                </child>
                <child>
                    <object class="GtkMenuItem" id="shutdown">
                        <property name="label">Shutdown</property>
                    </object>
                </child>
                <child>
                    <object class="GtkSeparatorMenuItem" id="delimiter1" />
                </child>
                <child>
                    <object class="GtkMenuItem" id="reboot">
                        <property name="label">Reboot</property>
                    </object>
                </child>
            </object>
        </interface>
      '';

      xdg.configFile."waybar/scripts/dunst.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          COUNT=$(${pkgs.dunst}/bin/dunstctl count waiting)
          ENABLED=
          DISABLED=

          if [ "$COUNT" != 0 ]; then
            DISABLED=" $COUNT"
          fi

          if ${pkgs.dunst}/bin/dunstctl is-paused | ${pkgs.gnugrep}/bin/grep -q false; then
            echo "$ENABLED"
          else
            echo "$DISABLED"
          fi
        '';
      };

      xdg.configFile."waybar/scripts/get_weather.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          exec ${pkgs.python3}/bin/python3 ${./files/waybar/weather.py}
        '';
      };

    }
  );
}
