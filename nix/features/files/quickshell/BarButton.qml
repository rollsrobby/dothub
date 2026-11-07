import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string text: ""
    property string tooltip: ""
    property color foreground: "#cdd6f4"
    property bool selected: false
    property real textOpacity: 1
    property int padding: 12
    signal clicked(int button)
    signal scrolled(real delta)
    implicitWidth: Math.max(12, label.implicitWidth) + padding * 2
    implicitHeight: 41
    color: mouse.containsMouse ? "#252536" : "transparent"
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.foreground
        opacity: root.textOpacity
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        font.bold: true
        textFormat: Text.PlainText
    }
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 3
        color: "#ad8ee6"
        visible: root.selected
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => root.scrolled(event.angleDelta.y)
    }
    ToolTip {
        parent: root
        popupType: Popup.Window
        y: root.height + 2
        visible: mouse.containsMouse && root.tooltip !== ""
        text: root.tooltip
        delay: 500
    }
}
