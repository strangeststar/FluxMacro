import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "./components"

ApplicationWindow {
    id: root
    visible: true
    width:  960
    height: 620
    minimumWidth:  780
    minimumHeight: 520
    title: "FluxMacro"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "#070709"

    // ── Palette — Behemoth / Da Hood dark theme ──────────────────────────────
    readonly property color bg:          "#070709"
    readonly property color surface:     "#0D0D12"
    readonly property color card:        "#111118"
    readonly property color border:      "#1E1E2A"
    readonly property color accent:      appSettings.accentColor
    readonly property color success:     "#1A8A30"
    readonly property color danger:      "#CC1111"
    readonly property color textPrimary: "#E8E8EE"
    readonly property color textMuted:   "#5A5A6E"
    readonly property color textDim:     "#2E2E3E"

    readonly property bool  anim:        appSettings.animationsEnabled
    readonly property int   animDur:     anim ? 200 : 0
    readonly property int   animDurFast: anim ? 120 : 0

    readonly property bool  isMaximized: root.visibility === Window.Maximized

    property int currentPage: 0   // 0=Macro  1=AutoClicker  2=Settings  3=Monitor

    Component.onCompleted: {
        windowHelper.applyFrameless(root)
    }

    // ── Window border ─────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(Qt.color(root.accent).r,
                              Qt.color(root.accent).g,
                              Qt.color(root.accent).b, 0.22)
        visible: !root.isMaximized
        z: 99
    }

    // ── Resize handles ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        z: 100
        visible: !root.isMaximized

        property int b: 6

        MouseArea {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: parent.b; bottomMargin: parent.b }
            width: parent.b; cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.LeftEdge)
        }
        MouseArea {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: parent.b; bottomMargin: parent.b }
            width: parent.b; cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.RightEdge)
        }
        MouseArea {
            anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: parent.b; rightMargin: parent.b }
            height: parent.b; cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.TopEdge)
        }
        MouseArea {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: parent.b; rightMargin: parent.b }
            height: parent.b; cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.BottomEdge)
        }
        MouseArea {
            anchors { top: parent.top; left: parent.left }
            width: parent.b; height: parent.b; cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
        }
        MouseArea {
            anchors { top: parent.top; right: parent.right }
            width: parent.b; height: parent.b; cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.TopEdge | Qt.RightEdge)
        }
        MouseArea {
            anchors { bottom: parent.bottom; left: parent.left }
            width: parent.b; height: parent.b; cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
        }
        MouseArea {
            anchors { bottom: parent.bottom; right: parent.right }
            width: parent.b; height: parent.b; cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
        }
    }

    // ── Root layout ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            Layout.fillWidth: true
            windowRef: root
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ── Sidebar ──────────────────────────────────────────────────────
            Rectangle {
                id: sidebar
                Layout.fillHeight: true
                width: 68
                color: root.surface

                Rectangle {
                    anchors.right: parent.right
                    width: 1; height: parent.height
                    color: root.border
                }

                ColumnLayout {
                    anchors {
                        top: parent.top; left: parent.left; right: parent.right
                        topMargin: 12
                    }
                    spacing: 4

                    Rectangle { Layout.fillWidth: true; height: 1; color: root.border; Layout.topMargin: 10; Layout.bottomMargin: 2 }

                    NavButton { icon: "⚡"; label: "Macro";       pageIndex: 0; currentPage: root.currentPage; onNavigateTo: (i) => root.currentPage = i }
                    NavButton { icon: "◎"; label: "AutoClick";   pageIndex: 1; currentPage: root.currentPage; onNavigateTo: (i) => root.currentPage = i }
                    NavButton { icon: "⚙"; label: "Settings";    pageIndex: 2; currentPage: root.currentPage; onNavigateTo: (i) => root.currentPage = i }
                    NavButton { icon: "◈"; label: "Monitor";     pageIndex: 3; currentPage: root.currentPage; onNavigateTo: (i) => root.currentPage = i }

                    Item { Layout.fillHeight: true }

                    Item {
                        Layout.fillWidth: true
                        height: 44
                        StatusPill { anchors.centerIn: parent; compact: true }
                    }
                }
            }

            // ── Main content ─────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // ── Top bar ──────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: root.surface

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1
                        color: root.border
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 20; rightMargin: 16 }
                        spacing: 12

                        Text {
                            text: ["Macro", "AutoClicker", "Settings", "Monitor"][root.currentPage]
                            font { pixelSize: 16; weight: Font.DemiBold }
                            color: root.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        StatusPill { compact: false }
                    }
                }

                // ── Pages ─────────────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Catches clicks on empty page background to clear TextField focus
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: root.contentItem.forceActiveFocus()
                    }

                    MacroPage {
                        anchors.fill: parent
                        visible: root.currentPage === 0
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: root.animDur } }
                    }

                    AutoClickerPage {
                        anchors.fill: parent
                        visible: root.currentPage === 1
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: root.animDur } }
                    }

                    SettingsPage {
                        anchors.fill: parent
                        visible: root.currentPage === 2
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: root.animDur } }
                    }

                    MonitorPage {
                        anchors.fill: parent
                        visible: root.currentPage === 3
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: root.animDur } }
                    }
                }

                // ── Status bar ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    color: "#05050A"

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width; height: 1
                        color: root.border
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        spacing: 0

                        Text {
                            text: "FluxMacro v2.0"
                            font.pixelSize: 11
                            color: root.textDim
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Macro: " + keyNames.nameOf(appSettings.macroHotkey)
                            font.pixelSize: 11; color: root.textDim
                        }
                        Text { text: "  ·  "; font.pixelSize: 11; color: root.textDim }
                        Text {
                            text: "AC: " + keyNames.nameOf(appSettings.acHotkey)
                            font.pixelSize: 11; color: root.textDim
                        }
                    }
                }
            }
        }
    }

    // Escape clears focus from any active text input
    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: root.contentItem.forceActiveFocus()
    }

    // ── Tray restore ──────────────────────────────────────────────────────────
    Connections {
        target: trayHelper
        function onRestoreRequested() {
            root.show()
            root.raise()
            root.requestActivate()
        }
    }

    // ── Reset-settings confirmation dialog ────────────────────────────────────
    Dialog {
        id: confirmReset
        title: "Restore Defaults?"
        modal: true
        x: root.width  / 2 - width  / 2
        y: root.height / 2 - height / 2
        width: 340; height: 140

        background: Rectangle {
            color: "#111118"; radius: 12
            border.color: "#2A2A3A"; border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 16
            Text {
                text: "All settings will be reset to defaults.\nSaved macros will not be affected."
                font.pixelSize: 13; color: "#CFCFCF"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8
                AnimButton { text: "Cancel"; onClicked: confirmReset.close() }
                AnimButton { text: "Reset"; danger: true
                    onClicked: { appSettings.resetToDefaults(); confirmReset.close() }
                }
            }
        }
    }
}
