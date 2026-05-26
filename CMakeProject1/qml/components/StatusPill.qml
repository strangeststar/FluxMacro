import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool compact: false

    readonly property bool macroRunning: macroEngine.anyActive
    readonly property bool acRunning:    autoClicker.running
    readonly property bool anyRunning:   macroRunning || acRunning

    width:  compact ? 36 : implicitWidth
    height: compact ? 36 : 30

    implicitWidth: compact ? 36 : row.implicitWidth + 24

    property color success: "#32D74B"
    property color border:  "#2A2A2A"

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: compact ? 18 : 15
        color: root.anyRunning ? "#1A3320" : "#1C1C1C"
        border.color: root.anyRunning ? root.success : root.border
        border.width: 1

        Behavior on color        { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Rectangle {
            anchors.centerIn: parent
            width: pulse.running ? pill.width + 10 : pill.width
            height: pulse.running ? pill.height + 10 : pill.height
            radius: pill.radius + 5
            color: "transparent"
            border.color: root.success
            border.width: 1
            opacity: 0
            visible: root.anyRunning

            SequentialAnimation on opacity {
                id: pulse
                running: root.anyRunning && appSettings.animationsEnabled
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.OutQuad }
                NumberAnimation { to: 0;    duration: 700; easing.type: Easing.InQuad  }
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                width: 7; height: 7; radius: 4
                color: root.anyRunning ? root.success : "#5E5E62"
                Behavior on color { ColorAnimation { duration: 200 } }

                SequentialAnimation on opacity {
                    running: root.anyRunning && appSettings.animationsEnabled
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 600 }
                    NumberAnimation { to: 1.0; duration: 600 }
                }
            }

            Text {
                visible: !root.compact
                text: root.anyRunning
                          ? (root.macroRunning ? "MACRO RUNNING" : "AC RUNNING")
                          : "STOPPED"
                font { pixelSize: 11; weight: Font.Bold; letterSpacing: 0.8 }
                color: root.anyRunning ? root.success : "#5E5E62"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
