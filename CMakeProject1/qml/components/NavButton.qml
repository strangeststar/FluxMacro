import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string icon:        ""
    property string label:       ""
    property int    pageIndex:   0
    property int    currentPage: -1

    signal navigateTo(int idx)

    Layout.fillWidth: true
    height: 56

    readonly property bool active: currentPage === pageIndex

    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 3; radius: 2
        color: root.active ? appSettings.accentColor : "transparent"
        Behavior on color { ColorAnimation { duration: appSettings.animationsEnabled ? 120 : 0 } }
    }

    Rectangle {
        anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 3; bottomMargin: 3 }
        radius: 8
        color: root.active
               ? Qt.rgba(Qt.color(appSettings.accentColor).r,
                         Qt.color(appSettings.accentColor).g,
                         Qt.color(appSettings.accentColor).b, 0.14)
               : hov.containsMouse ? "#1E1E1E" : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
        HoverHandler { id: hov }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:  root.icon
            font.pixelSize: 18
            color: root.active ? appSettings.accentColor : "#8E8E93"
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:  root.label
            font { pixelSize: 9; weight: Font.Medium }
            color: root.active ? appSettings.accentColor : "#5E5E62"
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.navigateTo(root.pageIndex)
    }
}
