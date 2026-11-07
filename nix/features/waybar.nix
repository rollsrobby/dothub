{ moduleWithSystem, ... }:
{
  flake.homeModules.waybar = moduleWithSystem (
    { pkgs, ... }:
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
      powerprofilesctl = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl";
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
            "group/tray-expander"
            "custom/dunst"
            "systemd-failed-units"
            "bluetooth"
            "network"
            "group/audio"
            "idle_inhibitor"
            "group/system-monitor"
            "power-profiles-daemon"
            "battery"
          ];

          "custom/nixos" = {
            format = "";
            tooltip = false;
            menu = "on-click";
            menu-file = "~/.config/waybar/power_menu.xml";
            menu-actions = {
              shutdown = "exec ${hyprshutdown} -t 'Shutting down...' --post-cmd 'shutdown -P 0'";
              reboot = "exec ${hyprshutdown} -t 'Restarting...' --post-cmd 'reboot'";
              suspend = "systemctl suspend";
              lock = "pidof hyprlock >/dev/null || ${hyprlock}";
            };
          };

          "custom/dunst" = {
            exec = "~/.config/waybar/scripts/dunst.sh";
            on-click = "${pkgs.dunst}/bin/dunstctl set-paused toggle";
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
              {
                type = "location";
                icon-name = "location-services-active-symbolic";
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
            format = "󰍛";
            tooltip-format = "CPU: {usage}%\nLoad: {load}";
            on-click = "${ghostty} -e ${btop}";
            on-click-right = ghostty;
          };

          memory = {
            interval = 10;
            format = "";
            tooltip-format = "Memory: {used:0.1f}/{total:0.1f} GiB ({percentage}%)\nZram: {swapUsed:0.1f}/{swapTotal:0.1f} GiB ({swapPercentage}%)";
            on-click = "${ghostty} -e ${btop}";
            states = {
              warning = 80;
              critical = 90;
            };
          };

          temperature = {
            hwmon-path-abs = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
            input-filename = "temp1_input";
            interval = 5;
            format = "{icon}";
            tooltip-format = "CPU temperature: {temperatureC}°C";
            format-icons = [
              ""
              ""
              ""
            ];
            warning-threshold = 85;
            critical-threshold = 95;
            on-click = "${ghostty} -e ${btop}";
          };

          disk = {
            path = "/";
            interval = 30;
            format = "󰋊";
            tooltip-format = "Disk: {used}/{total} used ({percentage_used}%)\nFree: {free}";
            on-click = "${ghostty} -e ${btop}";
            states = {
              warning = 80;
              critical = 90;
            };
          };

          "group/audio" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 200;
            };
            modules = [
              "pulseaudio"
              "pulseaudio/slider"
            ];
          };

          "group/system-monitor" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 300;
              children-class = "system-monitor-item";
            };
            modules = [
              "cpu"
              "memory"
              "temperature"
              "disk"
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

          "power-profiles-daemon" = {
            format = "{icon}";
            tooltip-format = "Power profile: {profile}\nDriver: {driver}";
            format-icons = {
              performance = "";
              balanced = "";
              "power-saver" = "";
            };
          };

          clock = {
            format = "{:L%a %b %d %H:%M}";
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
            format-wifi = "{icon}";
            format-ethernet = "󰀂";
            format-disconnected = "󰤮";
            tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-disconnected = "Disconnected";
            interval = 3;
            spacing = 1;
            on-click = "${ghostty} --title=wifitui -e ${wifitui}";
            on-click-right = "${ghostty} -e ${nmtui}";
          };

          battery = {
            format = "{capacity}% {icon}";
            format-discharging = "{icon}";
            format-charging = "{icon}";
            format-plugged = "";
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
            format-full = "󰂅";
            tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
            tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
            interval = 5;
            full-at = 80;
            menu = "on-click";
            menu-file = "~/.config/waybar/power_profile_menu.xml";
            menu-actions = {
              "power-saver" = "${powerprofilesctl} set power-saver";
              balanced = "${powerprofilesctl} set balanced";
              performance = "${powerprofilesctl} set performance";
            };
            states = {
              warning = 30;
              critical = 15;
            };
          };

          bluetooth = {
            format = "";
            format-off = "󰂲";
            format-disabled = "󰂲";
            format-connected = "󰂱";
            format-no-controller = "";
            tooltip-format = "Devices connected: {num_connections}";
            on-click = "${ghostty} --title=bluetui -e ${bluetui}";
            on-click-right = toggleBluetooth;
          };

          "pulseaudio/slider" = {
            min = 0;
            max = 100;
            orientation = "horizontal";
          };

          pulseaudio = {
            format = "{icon}";
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
              transition-duration = 600;
              children-class = "tray-group-item";
            };
            modules = [
              "custom/expand-icon"
              "tray"
            ];
          };

          "custom/expand-icon" = {
            format = "";
            tooltip = false;
          };

          tray = {
            icon-size = 12;
            spacing = 14;
          };
        }
      ];

      waybarStyle = builtins.readFile ./files/waybar/waybar.css;
    in
    {
      programs.waybar = {
        enable = true;
        package = pkgs.waybar.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./files/waybar/waybar-hyprland-lua.patch ];
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
          # Leaving the location empty lets wttr.in locate us by public IP.
          for i in {1..5}
          do
              text=$(curl -s "https://wttr.in/?format=1")
              if [[ $? == 0 ]]
              then
                  text=$(echo "$text" | sed -E "s/\s+/ /g")
                  tooltip=$(curl -s "https://wttr.in/?format=4")
                  if [[ $? == 0 ]]
                  then
                      tooltip=$(echo "$tooltip" | sed -E "s/\s+/ /g")
                      echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
                      exit
                  fi
              fi
              sleep 2
          done
          echo "{\"text\":\"error\", \"tooltip\":\"error\"}"
        '';
      };

    }
  );
}
