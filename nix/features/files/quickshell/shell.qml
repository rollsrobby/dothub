pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import "." as Theme

ShellRoot {
    id: root
    property var sink: Pipewire.defaultAudioSink
    property var battery: UPower.displayDevice
    property string weatherText: ""
    property string weatherTip: "Weather unavailable; click to retry"
    property bool weatherStale: false
    property bool inhibited: false
    function run(argv) { Quickshell.execDetached(argv); }
    function power(action, label) {
        run(["systemd-run", "--user", "--collect", "--unit=quickshell-power-action", "--",
             "hyprshutdown", "--no-fork", "-t", label, "--post-cmd", "systemctl " + action]);
    }
    function bluetoothAction(button) {
        run(button === Qt.RightButton
            ? ["bluetoothctl", "power", telemetry.statusData.bluetoothPowered ? "off" : "on"]
            : ["ghostty", "--title=bluetui", "-e", "bluetui"]);
    }
    function duration(seconds) {
        return seconds > 0 ? Math.floor(seconds / 3600) + "h " + Math.floor(seconds % 3600 / 60) + "m" : "estimating";
    }
    function calendarTooltip(date) {
        const first = new Date(date.getFullYear(), date.getMonth(), 1).getDay();
        const days = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
        let result = "<pre><b>" + Qt.formatDateTime(date, "MMMM yyyy") + "</b>\nSu Mo Tu We Th Fr Sa\n" + "   ".repeat(first);
        for (let day = 1; day <= days; ++day) {
            const label = String(day).padStart(2, " ");
            result += day === date.getDate() ? '<b><font color="' + Theme.Palette.accent + '">' + label + '</font></b>' : label;
            result += (first + day) % 7 === 0 ? "\n" : " ";
        }
        return result + "</pre>";
    }
    StreamJson {
        id: telemetry
        command: ["python3", Quickshell.shellPath("telemetry.py")]
    }
    PollText {
        id: profile
        interval: 2000
        command: ["power-profile-policy", "status"]
        property var statusData: ({})
        onReceived: output => { try { statusData = JSON.parse(output); } catch (error) { statusData = {}; } }
    }
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Timer {
        interval: 7200000
        running: root.inhibited
        onTriggered: root.inhibited = false
    }
    PollText {
        id: weather
        interval: 900000
        command: ["sh", "-c", "timeout 30s \"$HOME/.config/waybar/scripts/get_weather.sh\""]
        onReceived: output => {
            try {
                const data = JSON.parse(output);
                root.weatherText = data.text || "";
                root.weatherTip = data.tooltip || "";
                root.weatherStale = data.class === "stale" || data.class === "unavailable";
            } catch (error) {
                root.weatherTip = "Weather unavailable; click to retry";
            }
        }
    }
    StreamJson {
        id: notifications
        command: ["swaync-client", "-swb"]
        property int count: Number(statusData.text || 0)
        property bool dnd: String(statusData["alt"] || "").indexOf("dnd") >= 0 || String(statusData["alt"] || "").indexOf("inhibited") >= 0
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 45
            exclusiveZone: 45
            color: Theme.Palette.surface
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top
            property bool trayExpanded: false
            property bool audioExpanded: false
            IdleInhibitor { window: bar; enabled: root.inhibited }

            Row {
                id: leftGroup
                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                BarButton {
                    text: ""
                    padding: 8
                    tooltip: "Power menu"
                    onClicked: powerMenu.open()
                    BarMenu {
                        id: powerMenu
                        popupType: Popup.Window
                        y: parent.height
                        MenuItem { text: "Lock"; onTriggered: root.run(["sh", "-c", "pidof hyprlock >/dev/null || hyprlock"]) }
                        MenuItem { text: "Suspend"; onTriggered: root.run(["systemctl", "suspend"]) }
                        MenuSeparator {}
                        MenuItem { text: "Shutdown"; onTriggered: root.power("poweroff", "Shutting down...") }
                        MenuItem { text: "Reboot"; onTriggered: root.power("reboot", "Restarting...") }
                    }
                }
                Repeater {
                    model: {
                        const ids = [1, 2, 3, 4, 5, 6, 7, 8];
                        for (const w of Hyprland.workspaces.values)
                            if (w.id > 0 && ids.indexOf(w.id) < 0) ids.push(w.id);
                        return ids.sort((a, b) => a - b);
                    }
                    BarButton {
                        required property int modelData
                        property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData) || null
                        text: modelData === 10 ? "0" : String(modelData)
                        implicitWidth: 29
                        foreground: Theme.Palette.accent
                        selected: workspace !== null && workspace.active
                        textOpacity: selected || (workspace && workspace.toplevels.values.length > 0) ? 1 : 0.3
                        highlight: workspace && workspace.urgent ? Theme.Palette.danger : Theme.Palette.workspaceActive
                        tinted: selected || (workspace !== null && workspace.urgent)
                        tintOpacity: workspace && workspace.urgent ? 1 : 0.09
                        tooltip: "Workspace " + modelData
                        onClicked: Hyprland.dispatch(Hyprland.usingLua
                            ? 'hl.dsp.focus({ workspace = "' + modelData + '" })'
                            : "workspace " + modelData)
                    }
                }
            }

            Row {
                id: center
                // Prefer screen center, but never cover either control group.
                property real availableWidth: Math.max(0, rightGroup.x - leftGroup.x - leftGroup.width - 16)
                width: Math.min(implicitWidth, availableWidth)
                clip: true
                x: Math.max(leftGroup.x + leftGroup.width + 8,
                    Math.min((bar.width - width) / 2, rightGroup.x - width - 8))
                anchors.verticalCenter: parent.verticalCenter
                BarButton {
                    id: privacyButton
                    property var streams: telemetry.statusData.privacy || ({microphone: [], screenshare: []})
                    visible: streams.microphone.length + streams.screenshare.length > 0
                    text: (streams.screenshare.length ? "󰍹 " : "") + (streams.microphone.length ? "" : "")
                    foreground: Theme.Palette.danger
                    highlight: Theme.Palette.danger
                    tinted: true
                    tintOpacity: 0.14
                    implicitHeight: 33
                    anchors.verticalCenter: parent.verticalCenter
                    tooltip: (streams.screenshare.length ? "Screen sharing: " + streams.screenshare.join(", ") + "\n" : "")
                        + (streams.microphone.length ? "Microphone: " + streams.microphone.join(", ") : "")
                }
                BarButton {
                    id: clockButton
                    text: Qt.formatDateTime(clock.date, "ddd MMM dd") + "  <b>" + Qt.formatDateTime(clock.date, "HH:mm") + "</b>"
                    textFormat: Text.RichText
                    bold: false
                    padding: 8
                    tooltip: root.calendarTooltip(clock.date)
                    onClicked: calendar.open()
                    Popup {
                        id: calendar
                        popupType: Popup.Window
                        focus: true
                        y: parent.height
                        padding: 12
                        background: Rectangle { color: Theme.Palette.surface; border.color: Theme.Palette.workspaceActive; radius: 8 }
                        contentItem: Column {
                            spacing: 8
                            Text { text: Qt.formatDateTime(clock.date, "MMMM yyyy"); color: Theme.Palette.text; font.bold: true }
                            MonthGrid {
                                month: clock.date.getMonth()
                                year: clock.date.getFullYear()
                                locale: Qt.locale()
                                delegate: Text {
                                    required property var model
                                    text: model.day
                                    color: model.today ? Theme.Palette.accent : Theme.Palette.text
                                    opacity: model.month === clock.date.getMonth() ? 1 : 0.3
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.bold: model.today
                                }
                            }
                        }
                    }
                }
                BarButton {
                    visible: root.weatherText !== "" && center.availableWidth >= clockButton.width + implicitWidth + (privacyButton.visible ? privacyButton.width : 0)
                    text: root.weatherText
                    fontSize: 14
                    bold: false
                    textOpacity: root.weatherStale ? 0.55 : 1
                    tooltip: root.weatherTip
                    padding: 8
                    onClicked: weather.refresh()
                }
            }

            Row {
                id: rightGroup
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                BarButton {
                    text: "CPU " + (telemetry.available ? telemetry.statusData.cpu + "%" : "—")
                    fontSize: 13
                    bold: false
                    implicitWidth: 88
                    tooltip: "CPU: " + (telemetry.statusData.cpu || 0) + "%\nLoad: " + (telemetry.statusData.load || 0)
                    onClicked: button => root.run(button === Qt.RightButton ? ["ghostty"] : ["ghostty", "-e", "btop"])
                }
                BarButton {
                    text: "RAM " + (telemetry.available ? telemetry.statusData.ram + "%" : "—")
                    fontSize: 13
                    bold: false
                    implicitWidth: 88
                    foreground: telemetry.statusData.ram >= 90 ? Theme.Palette.danger : telemetry.statusData.ram >= 80 ? Theme.Palette.warning : Theme.Palette.text
                    tooltip: telemetry.statusData.memoryTip || "Memory unavailable"
                    onClicked: root.run(["ghostty", "-e", "btop"])
                }
                Rectangle { width: 1; height: 25; anchors.verticalCenter: parent.verticalCenter; color: Qt.alpha(Theme.Palette.text, 0.16) }
                BarButton {
                    property var network: telemetry.statusData.network || ({})
                    text: network.text || "󰤮"
                    foreground: network.connected ? Theme.Palette.text : Theme.Palette.danger
                    tooltip: network.tooltip || "Network unavailable"
                    onClicked: button => root.run(button === Qt.RightButton
                        ? ["ghostty", "-e", "nmtui"] : ["ghostty", "--title=wifitui", "-e", "wifitui"])
                }
                BarButton {
                    visible: (telemetry.statusData.bluetooth || []).length > 0
                    text: "󰂱"
                    tooltip: "Devices connected: " + (telemetry.statusData.bluetooth || []).length + "\n" + (telemetry.statusData.bluetooth || []).join("\n")
                    onClicked: button => root.bluetoothAction(button)
                }
                BarButton {
                    text: !root.sink || !root.sink.audio || root.sink.audio.muted ? ""
                        : ((/headphone|headset/i.test(root.sink.description) ? "" : root.sink.audio.volume > 0.5 ? "" : root.sink.audio.volume > 0 ? "" : "") + " " + Math.round(root.sink.audio.volume * 100) + "%")
                    tooltip: root.sink && root.sink.audio
                        ? root.sink.description + ": " + Math.round(root.sink.audio.volume * 100) + "%\nRight-click mute · middle-click slider · scroll volume"
                        : "No audio output"
                    onClicked: button => {
                        if (button === Qt.MiddleButton) bar.audioExpanded = !bar.audioExpanded;
                        else if (button === Qt.RightButton) {
                            if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted;
                        } else root.run(["pavucontrol"]);
                    }
                    onScrolled: delta => {
                        if (root.sink && root.sink.audio)
                            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + (delta > 0 ? 0.05 : -0.05)));
                    }
                }
                Slider {
                    visible: bar.audioExpanded
                    width: 80
                    height: 41
                    from: 0; to: 1
                    value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                    onMoved: if (root.sink && root.sink.audio) root.sink.audio.volume = value
                }
                BarButton {
                    text: profile.statusData.text || "?"
                    tooltip: profile.statusData.tooltip || "Power profile unavailable"
                    onClicked: profileMenu.open()
                    ProfileMenu { id: profileMenu; status: profile.statusData; onChanged: profile.refresh() }
                }
                BarButton {
                    visible: root.battery && root.battery.isPresent
                    property real percent: root.battery ? root.battery.percentage : 1
                    property bool charging: root.battery && root.battery.state === UPowerDeviceState.Charging
                    property bool full: percent >= 0.80 && !UPower.onBattery
                    property int level: Math.max(0, Math.min(9, Math.floor(percent * 10)))
                    text: (full ? "󰂅" : charging ? ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"][level]
                        : !UPower.onBattery ? "" : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][level]) + " " + Math.round(percent * 100) + "%"
                    foreground: percent <= 0.15 ? Theme.Palette.danger : percent <= 0.30 ? Theme.Palette.warning : Theme.Palette.text
                    tooltip: root.battery ? UPowerDeviceState.toString(root.battery.state) + ": " + Math.round(percent * 100) + "%\n"
                        + (full ? "Configured charge target reached" : (charging ? "Time to full: " : "Remaining: ") + root.duration(charging ? root.battery.timeToFull : root.battery.timeToEmpty))
                        + " · " + root.battery.changeRate.toFixed(1) + " W\nClick to choose a power profile" : ""
                    onClicked: batteryMenu.open()
                    ProfileMenu { id: batteryMenu; status: profile.statusData; onChanged: profile.refresh() }
                }
                Rectangle { width: 1; height: 25; anchors.verticalCenter: parent.verticalCenter; color: Qt.alpha(Theme.Palette.text, 0.16) }
                BarButton {
                    visible: (telemetry.statusData.failed || []).length > 0
                    text: " " + (telemetry.statusData.failed || []).length
                    foreground: Theme.Palette.danger
                    tooltip: (telemetry.statusData.failed || []).join("\n")
                    onClicked: root.run(["ghostty", "--title=failed-units", "-e", "bash", Quickshell.shellPath("failed-units.sh")])
                }
                BarButton {
                    text: root.inhibited ? "" : ""
                    opticalOffset: -4
                    implicitHeight: 33
                    anchors.verticalCenter: parent.verticalCenter
                    foreground: root.inhibited ? Theme.Palette.accent : Qt.alpha(Theme.Palette.text, 0.45)
                    selected: root.inhibited
                    highlight: Theme.Palette.accent
                    tintOpacity: 0.16
                    tooltip: root.inhibited ? "Idle inhibition active; click to disable" : "Idle inhibition inactive; click to enable for up to 2 hours"
                    onClicked: root.inhibited = !root.inhibited
                }
                BarButton {
                    text: (notifications.dnd ? (notifications.count > 0 ? "" : "") : (notifications.count > 0 ? "󱅫" : ""))
                        + (notifications.count > 0 ? " " + notifications.count : "")
                    tooltip: (notifications.available ? notifications.count + " notifications" + (notifications.dnd ? " · Do Not Disturb / inhibited" : "") : "Notification service unavailable")
                        + "\nClick: open history\nRight-click: Do Not Disturb"
                    onClicked: button => root.run(["swaync-client", button === Qt.RightButton ? "-d" : "-t", "-sw"])
                }
                Rectangle {
                    width: drawer.width
                    height: 33
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 6
                    color: bar.trayExpanded ? Qt.alpha(Theme.Palette.text, 0.04) : "transparent"
                    Row {
                        id: drawer
                        BarButton {
                            text: "󰍜"
                            implicitHeight: 33
                            selected: bar.trayExpanded
                            highlight: Theme.Palette.selection
                            foreground: bar.trayExpanded ? Theme.Palette.selection : Theme.Palette.text
                            tintOpacity: 0.16
                            tooltip: "Click to show/hide Bluetooth and tray"
                            onClicked: bar.trayExpanded = !bar.trayExpanded
                        }
                        Row {
                            visible: bar.trayExpanded
                            BarButton {
                                text: ""
                                implicitHeight: 33
                                tooltip: "Bluetooth devices (right-click to toggle)"
                                onClicked: button => root.bluetoothAction(button)
                            }
                            Repeater {
                                model: SystemTray.items
                                Rectangle {
                                    id: trayItem
                                    required property var modelData
                                    width: 36
                                    height: 33
                                    radius: 6
                                    color: trayMouse.containsMouse ? Qt.alpha(Theme.Palette.text, 0.04) : "transparent"
                                    Image { anchors.centerIn: parent; width: 16; height: 16; source: trayItem.modelData.icon }
                                    MouseArea {
                                        id: trayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                        onClicked: event => {
                                            if (event.button === Qt.MiddleButton) trayItem.modelData.secondaryActivate();
                                            else if (event.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                                                const point = trayItem.mapToItem(bar.contentItem, 0, trayItem.height);
                                                trayItem.modelData.display(bar, point.x, point.y);
                                            } else trayItem.modelData.activate();
                                        }
                                        onWheel: event => trayItem.modelData.scroll(event.angleDelta.y, false)
                                    }
                                    ToolTip {
                                        parent: trayItem
                                        popupType: Popup.Window
                                        y: trayItem.height + 2
                                        visible: trayMouse.containsMouse
                                        text: trayItem.modelData.tooltipTitle || trayItem.modelData.title
                                        delay: 500
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
