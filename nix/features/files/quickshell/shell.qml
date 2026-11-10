import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

ShellRoot {
    id: root
    property var sink: Pipewire.defaultAudioSink
    property var battery: UPower.displayDevice
    property string weatherText: ""
    property string weatherTip: "Weather unavailable; click to retry"
    property bool inhibited: false
    function run(argv) { Quickshell.execDetached(argv); }
    function profileNext() {
        PowerProfiles.profile = PowerProfiles.profile === PowerProfile.PowerSaver
            ? PowerProfile.Balanced
            : PowerProfiles.profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile
                ? PowerProfile.Performance : PowerProfile.PowerSaver;
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
            } catch (error) {
                root.weatherTip = "Weather unavailable; click to retry";
            }
        }
    }
    PollText {
        id: notifications
        interval: 1000
        command: ["swaync-client", "-c"]
    }
    PollText {
        id: network
        interval: 5000
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        property bool wifi: text.indexOf("wifi:connected:") >= 0
        property bool connected: wifi || text.indexOf("ethernet:connected:") >= 0
    }
    PollText {
        id: bluetooth
        interval: 5000
        command: ["bluetoothctl", "show"]
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
            color: "#181824"
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top
            property bool trayExpanded: false
            property bool audioExpanded: false
            IdleInhibitor { window: bar; enabled: root.inhibited }

            Row {
                id: left
                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                BarButton {
                    text: ""
                    padding: 8
                    tooltip: "Power menu"
                    onClicked: powerMenu.open()
                    Menu {
                        id: powerMenu
                        popupType: Popup.Window
                        y: parent.height
                        MenuItem { text: "Lock"; onTriggered: root.run(["sh", "-c", "pidof hyprlock >/dev/null || hyprlock"]) }
                        MenuItem { text: "Suspend"; onTriggered: root.run(["systemctl", "suspend"]) }
                        MenuSeparator {}
                        MenuItem { text: "Shutdown"; onTriggered: root.run(["hyprshutdown", "-t", "Shutting down...", "--post-cmd", "shutdown -P 0"]) }
                        MenuItem { text: "Reboot"; onTriggered: root.run(["hyprshutdown", "-t", "Restarting...", "--post-cmd", "reboot"]) }
                    }
                }
                Repeater {
                    model: 8
                    BarButton {
                        required property int index
                        property var workspace: Hyprland.workspaces.values.find(w => w.id === index + 1) || null
                        text: String(index + 1)
                        padding: 9
                        foreground: "#0db9d7"
                        selected: workspace !== null && workspace.active
                        textOpacity: selected || (workspace && workspace.toplevels.values.length > 0) ? 1 : 0.3
                        color: workspace && workspace.urgent ? "#f7768e" : "transparent"
                        tooltip: "Workspace " + (index + 1)
                        onClicked: Hyprland.dispatch(Hyprland.usingLua
                            ? 'hl.dsp.focus({ workspace = "' + (index + 1) + '" })'
                            : "workspace " + (index + 1))
                    }
                }
            }

            Row {
                id: center
                // Prefer screen center, but never cover either control group.
                property real availableWidth: Math.max(0, right.x - left.x - left.width - 16)
                x: Math.max(left.x + left.width + 8,
                    Math.min((bar.width - width) / 2, right.x - width - 8))
                anchors.verticalCenter: parent.verticalCenter
                BarButton {
                    id: clockButton
                    text: Qt.formatDateTime(clock.date, "ddd MMM dd HH:mm")
                    padding: 8
                    tooltip: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")
                    onClicked: calendar.open()
                    Popup {
                        id: calendar
                        popupType: Popup.Window
                        focus: true
                        y: parent.height
                        padding: 12
                        background: Rectangle { color: "#181824"; border.color: "#ad8ee6"; radius: 8 }
                        contentItem: Column {
                            spacing: 8
                            Text { text: Qt.formatDateTime(clock.date, "MMMM yyyy"); color: "#cdd6f4"; font.bold: true }
                            MonthGrid {
                                month: clock.date.getMonth()
                                year: clock.date.getFullYear()
                                locale: Qt.locale()
                                delegate: Text {
                                    required property var model
                                    text: model.day
                                    color: model.today ? "#0db9d7" : "#cdd6f4"
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
                    visible: root.weatherText !== "" && center.availableWidth >= clockButton.width + implicitWidth
                    text: root.weatherText
                    tooltip: root.weatherTip
                    padding: 8
                    onClicked: weather.refresh()
                }
            }

            Row {
                id: right
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                BarButton {
                    text: bar.trayExpanded ? "" : ""
                    tooltip: "Toggle system tray"
                    padding: 9
                    onClicked: bar.trayExpanded = !bar.trayExpanded
                }
                Row {
                    visible: bar.trayExpanded
                    spacing: 14
                    Repeater {
                        model: SystemTray.items
                        Item {
                            id: trayItem
                            required property var modelData
                            width: 16
                            height: 41
                            Image { anchors.centerIn: parent; width: 12; height: 12; source: trayItem.modelData.icon }
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
                BarButton {
                    text: Number(notifications.text) > 0 ? "󱅫" : ""
                    padding: 8
                    tooltip: "Open notification history"
                    onClicked: root.run(["swaync-client", "-t"])
                }
                BarButton {
                    visible: bluetooth.text !== ""
                    text: bluetooth.text.indexOf("Powered: yes") >= 0 ? "" : "󰂲"
                    tooltip: "Bluetooth (right-click to toggle)"
                    onClicked: button => {
                        if (button === Qt.RightButton) root.run(["bluetoothctl", "power", bluetooth.text.indexOf("Powered: yes") >= 0 ? "off" : "on"]);
                        else root.run(["ghostty", "--title=bluetui", "-e", "bluetui"]);
                    }
                }
                BarButton {
                    text: network.wifi ? "󰤨" : network.connected ? "󰀂" : "󰤮"
                    foreground: network.connected ? "#cdd6f4" : "#f7768e"
                    tooltip: network.text || "Network unavailable"
                    onClicked: button => root.run(button === Qt.RightButton
                        ? ["ghostty", "-e", "nmtui"] : ["ghostty", "--title=wifitui", "-e", "wifitui"])
                }
                BarButton {
                    text: !root.sink || !root.sink.audio || root.sink.audio.muted ? ""
                        : root.sink.audio.volume > 0.5 ? "" : ""
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
                    text: root.inhibited ? "" : ""
                    foreground: root.inhibited ? "#0db9d7" : "#cdd6f4"
                    tooltip: root.inhibited ? "Idle inhibition active; click to disable" : "Inhibit idle for up to 2 hours"
                    onClicked: root.inhibited = !root.inhibited
                }
                BarButton {
                    text: "󰍛"
                    tooltip: "System monitor"
                    onClicked: button => root.run(button === Qt.RightButton ? ["ghostty"] : ["ghostty", "-e", "btop"])
                }
                BarButton {
                    text: PowerProfiles.profile === PowerProfile.PowerSaver ? ""
                        : PowerProfiles.profile === PowerProfile.Performance ? "" : ""
                    tooltip: "Power profile: " + PowerProfile.toString(PowerProfiles.profile) + " (click to cycle)"
                    onClicked: root.profileNext()
                }
                BarButton {
                    visible: root.battery && root.battery.isPresent
                    property real percent: root.battery ? root.battery.percentage : 1
                    text: root.battery && root.battery.state === UPowerDeviceState.Charging ? "󰂅"
                        : !UPower.onBattery ? ""
                        : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.min(9, Math.floor(percent * 10))]
                    foreground: percent <= 0.15 ? "#f7768e" : percent <= 0.30 ? "#e0af68" : "#cdd6f4"
                    tooltip: root.battery ? Math.round(percent * 100) + "% · " + root.battery.changeRate.toFixed(1) + " W\nClick to cycle power profile" : ""
                    onClicked: root.profileNext()
                }
            }
        }
    }
}
