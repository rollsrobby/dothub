import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Io

BarMenu {
    id: profilePopup
    popupType: Popup.Window
    y: parent.height
    property var status: ({})
    property string error: ""
    signal changed()
    function choose(mode) {
        if (action.running) return;
        error = "";
        action.command = ["power-profile-policy", mode];
        action.running = true;
    }
    Process {
        id: action
        stderr: StdioCollector { onStreamFinished: profilePopup.error = text.trim() }
        onExited: (code, status) => {
            profilePopup.changed();
            if (code !== 0) {
                if (!profilePopup.error) profilePopup.error = "Profile change failed";
                profilePopup.open();
            }
        }
    }
    MenuItem { text: profilePopup.status.tooltip ? profilePopup.status.tooltip.split("\n")[0] : "Power profile"; enabled: false }
    MenuSeparator {}
    MenuItem { text: "Automatic"; onTriggered: profilePopup.choose("auto") }
    MenuItem { text: "Power Saver"; onTriggered: profilePopup.choose("power-saver") }
    MenuItem { text: "Balanced"; onTriggered: profilePopup.choose("balanced") }
    MenuItem { text: "Performance"; onTriggered: profilePopup.choose("performance") }
    MenuItem { visible: profilePopup.error !== ""; text: profilePopup.error; enabled: false }
}
