import QtQuick
import QtQuick.Controls.Basic

Rectangle {
    id: root
    property string text:      ""
    property color  baseColor: "#2A2A2A"
    property color  textColor: "#FFFFFF"
    property bool   primary:   false
    property bool   danger:    false
    property real   radius:    8

    signal clicked()

    implicitWidth:  textItem.implicitWidth + 32
    implicitHeight: 34

    color: {
        if (primary) return appSettings.accentColor
        if (danger)  return "#3A1515"
        return ma.pressed ? Qt.lighter(root.baseColor, 1.15)
                          : ma.containsMouse ? Qt.lighter(root.baseColor, 1.08)
                                             : root.baseColor
    }

    border.color: {
        if (primary) return Qt.lighter(appSettings.accentColor, 1.1)
        if (danger)  return "#FF453A"
        return "#3A3A3A"
    }
    border.width: 1

    Behavior on color        { ColorAnimation { duration: 80 } }
    Behavior on border.color { ColorAnimation { duration: 80 } }

    scale: ma.pressed && appSettings.animationsEnabled ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

    Text {
        id: textItem
        anchors.centerIn: parent
        text: root.text
        font { pixelSize: 13; weight: Font.Medium }
        color: root.danger ? "#FF453A" : root.textColor
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: forceActiveFocus()
        onClicked: root.clicked()
    }
}
