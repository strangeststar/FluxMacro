import QtQuick

Item {
    id: root
    property bool   checked: false
    property string label:   ""
    signal toggled(bool value)

    implicitWidth:  label.length > 0 ? track.width + 10 + lbl.implicitWidth : track.width
    implicitHeight: 24

    Rectangle {
        id: track
        width: 44; height: 24; radius: 12
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? appSettings.accentColor : "#2E2E2E"
        Behavior on color { ColorAnimation { duration: appSettings.animationsEnabled ? 180 : 0 } }

        Rectangle {
            id: thumb
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: "#FFFFFF"
            Behavior on x { NumberAnimation { duration: appSettings.animationsEnabled ? 180 : 0; easing.type: Easing.OutCubic } }
        }
    }

    Text {
        id: lbl
        anchors { left: track.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
        text: root.label
        font.pixelSize: 13
        color: "#CFCFCF"
        visible: root.label.length > 0
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Only emit — never write root.checked imperatively so parent bindings stay alive
        onClicked: root.toggled(!root.checked)
    }
}
