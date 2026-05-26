import QtQuick
import QtQuick.Layouts

// Inline hotkey capture button — click to start capture, press any key/mouse button.
// capturing state is tracked locally so the UI updates correctly.
Item {
    id: root
    property var    hotkeyManager: null
    property int    currentVK:     0
    property string currentName:   keyNames.nameOf(currentVK)

    // Local state — toggled on click, cleared when a key is captured
    property bool capturing: false

    implicitWidth:  btn.implicitWidth
    implicitHeight: btn.implicitHeight

    Connections {
        target: root.hotkeyManager
        function onKeyCaptured(vk, name) {
            root.capturing = false
            root.currentVK = vk
        }
    }

    Rectangle {
        id: btn
        implicitWidth:  label.implicitWidth + 40
        implicitHeight: 34
        radius: 8
        color: root.capturing ? "#2A2200" : (ma.containsMouse ? "#252525" : "#1E1E1E")
        border.color: root.capturing ? "#FFD60A" : "#3A3A3A"
        border.width: root.capturing ? 2 : 1
        Behavior on color        { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        // Pulsing opacity while waiting for key
        SequentialAnimation on opacity {
            running: root.capturing && appSettings.animationsEnabled
            loops: Animation.Infinite
            NumberAnimation { to: 0.5; duration: 400 }
            NumberAnimation { to: 1.0; duration: 400 }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.capturing ? "Press any key / button…" : ("[ " + root.currentName + " ]")
            font { pixelSize: 13; weight: root.capturing ? Font.Normal : Font.Medium }
            color: root.capturing ? "#FFD60A" : "#CFCFCF"
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!root.hotkeyManager) return
                if (root.capturing) {
                    root.hotkeyManager.cancelCapture()
                    root.capturing = false
                } else {
                    root.hotkeyManager.beginCapture()
                    root.capturing = true
                }
            }
        }
    }
}
