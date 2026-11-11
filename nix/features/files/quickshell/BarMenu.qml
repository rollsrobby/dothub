import QtQuick
import QtQuick.Controls.Basic
import "." as Theme

Menu {
    popupType: Popup.Window
    y: parent.height
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 16
    palette.windowText: Theme.Palette.warning
    palette.text: Theme.Palette.warning
    palette.light: Qt.alpha(Theme.Palette.selection, 0.16)
    palette.midlight: Qt.alpha(Theme.Palette.selection, 0.25)
    background: Rectangle {
        implicitWidth: 300
        color: Theme.Palette.menuSurface
        radius: 15
    }
}
