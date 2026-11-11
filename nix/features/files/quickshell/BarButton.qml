import QtQuick
import QtQuick.Controls
import "." as Theme

Rectangle {
    id: root
    property string text: ""
    property string tooltip: ""
    property color foreground: Theme.Palette.text
    property color highlight: Theme.Palette.workspaceActive
    property bool selected: false
    property bool tinted: selected
    property real tintOpacity: 0.09
    property int fontSize: 16
    property bool bold: true
    property real opticalOffset: 0
    property int textFormat: Text.PlainText
    property real textOpacity: 1
    property int padding: 8
    signal clicked(int button)
    signal scrolled(real delta)
    implicitWidth: Math.max(20, label.implicitWidth) + padding * 2
    implicitHeight: 41
    radius: 6
    color: tinted ? Qt.alpha(highlight, tintOpacity) : mouse.containsMouse ? Qt.alpha(Theme.Palette.text, 0.04) : "transparent"
    Text {
        id: label
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.opticalOffset
        text: root.text
        color: root.foreground
        opacity: root.textOpacity
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.fontSize
        font.bold: root.bold
        textFormat: root.textFormat
    }
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 3
        color: root.highlight
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
        palette.windowText: Theme.Palette.text
        background: Rectangle { color: Theme.Palette.menuSurface; radius: 6 }
    }
}
