import QtQuick
import Quickshell.Io

// Reconnect subscriptions after daemon restarts without busy-looping.
Item {
    id: root
    property list<string> command: []
    property var statusData: ({})
    property bool available: false
    Process {
        id: process
        command: root.command
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { root.statusData = JSON.parse(line); root.available = true; }
                catch (error) { console.warn("Invalid status JSON:", error); }
            }
        }
        onExited: { root.available = false; restart.start(); }
    }
    Timer { id: restart; interval: 5000; onTriggered: process.running = true }
}
