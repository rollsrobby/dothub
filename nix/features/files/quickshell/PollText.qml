import QtQuick
import Quickshell.Io

// One process per poller, shared by every monitor. Never overlap slow requests.
Item {
    id: root
    property list<string> command: []
    property int interval: 5000
    property string text: ""
    signal received(string output)
    function refresh() { if (!process.running) process.running = true; }
    Component.onCompleted: refresh()
    Timer { interval: root.interval; running: true; repeat: true; onTriggered: root.refresh() }
    Process {
        id: process
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: {
                root.text = text.trim();
                root.received(root.text);
            }
        }
    }
}
