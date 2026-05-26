import QtQuick
import QtQuick.Controls.Basic

Slider {
    id: root
    implicitHeight: 36

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 200; implicitHeight: 4
        width: root.availableWidth; height: implicitHeight
        radius: 2
        color: "#2E2E2E"

        Rectangle {
            width:  root.visualPosition * parent.width
            height: parent.height
            radius: 2
            color:  appSettings.accentColor
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding  + root.availableHeight / 2 - height / 2
        implicitWidth: 18; implicitHeight: 18
        radius: 9
        color: root.pressed ? Qt.lighter(appSettings.accentColor, 1.2) : "#FFFFFF"
        border.color: appSettings.accentColor
        border.width: 2

        scale: root.pressed ? 1.15 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
    }
}
