import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

Item {
    id: root
    property var  windowRef:  null
    property bool maximized:  windowRef ? (windowRef.visibility === Window.Maximized) : false

    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        color: "#09090F"

        // Accent-tinted bottom border
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Qt.rgba(Qt.color(appSettings.accentColor).r,
                           Qt.color(appSettings.accentColor).g,
                           Qt.color(appSettings.accentColor).b, 0.45)
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 0 }
            spacing: 8

            // Left accent bar
            Rectangle {
                width: 3; height: 18; radius: 2
                color: appSettings.accentColor
                opacity: 0.8
            }

            Text {
                text: "FLUXMACRO"
                font { pixelSize: 12; weight: Font.Bold; letterSpacing: 2.0 }
                color: appSettings.accentColor
            }

            Item { Layout.fillWidth: true }

            // Window control buttons
            Row {
                spacing: 0

                // Send to tray
                Rectangle {
                    width: trayRow.implicitWidth + 20; height: 40
                    color: trayBtnHov.containsMouse ? "#18181E" : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Row {
                        id: trayRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: "⬇"
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: trayBtnHov.containsMouse ? "#AAAACC" : "#5A5A6E"
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }
                        Text {
                            text: "Tray"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                            color: trayBtnHov.containsMouse ? "#AAAACC" : "#5A5A6E"
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }
                    }
                    HoverHandler { id: trayBtnHov }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: trayHelper.sendToTray(root.windowRef)
                    }
                }

                // Minimize
                Rectangle {
                    width: 46; height: 40
                    color: minHov.containsMouse ? "#18181E" : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: "─"
                        font.pixelSize: 11
                        color: minHov.containsMouse ? "#AAAACC" : "#5A5A6E"
                    }
                    HoverHandler { id: minHov }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { if (root.windowRef) root.windowRef.showMinimized() }
                    }
                }

                // Maximize / Restore
                Rectangle {
                    width: 46; height: 40
                    color: maxHov.containsMouse ? "#18181E" : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: root.maximized ? "❐" : "⬜"
                        font.pixelSize: root.maximized ? 12 : 11
                        color: maxHov.containsMouse ? "#AAAACC" : "#5A5A6E"
                    }
                    HoverHandler { id: maxHov }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (!root.windowRef) return
                            if (root.maximized) root.windowRef.showNormal()
                            else root.windowRef.showMaximized()
                        }
                    }
                }

                // Close
                Rectangle {
                    width: 46; height: 40
                    color: closeHov.containsMouse ? "#8B0010" : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 11
                        color: closeHov.containsMouse ? "#FFFFFF" : "#5A5A6E"
                    }
                    HoverHandler { id: closeHov }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { if (root.windowRef) root.windowRef.close() }
                    }
                }
            }
        }

        DragHandler {
            target: null
            onActiveChanged: if (active && root.windowRef) root.windowRef.startSystemMove()
        }

        TapHandler {
            gesturePolicy: TapHandler.DragThreshold
            onDoubleTapped: {
                if (!root.windowRef) return
                if (root.maximized) root.windowRef.showNormal()
                else root.windowRef.showMaximized()
            }
        }
    }
}
