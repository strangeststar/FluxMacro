import QtQuick

Item {
    property string text: ""
    implicitHeight: 28
    width: parent ? parent.width : 200

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: parent.text
        font { pixelSize: 10; weight: Font.Bold; letterSpacing: 1.2 }
        color: appSettings.accentColor
        opacity: 0.85
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: "#2A2A2A"
    }
}
