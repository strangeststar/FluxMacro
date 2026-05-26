import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "./components"

Item {
    id: root

    Component.onCompleted: {
        autoClicker.setClickType(appSettings.acClickType)
        autoClicker.setCPS(appSettings.acCPS)
        autoClicker.setSafeTaskbar(appSettings.acSafeTaskbar)
        autoClicker.setSafeTitlebar(appSettings.acSafeTitlebar)
    }

    RowLayout {
        anchors { fill: parent; margins: 20 }
        spacing: 16

        // ── Left: status + controls ──────────────────────────────────────────
        ColumnLayout {
            Layout.preferredWidth: 290
            Layout.fillHeight: true
            spacing: 12

            // Master Enable switch
            GlassCard {
                Layout.fillWidth: true
                height: 72

                RowLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "Master Enable"
                            font { pixelSize: 13; weight: Font.DemiBold }
                            color: appSettings.acMasterEnabled ? "#FFFFFF" : "#8E8E93"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: appSettings.acMasterEnabled ? "AutoClicker is active" : "AutoClicker is disabled"
                            font.pixelSize: 11
                            color: appSettings.acMasterEnabled ? appSettings.accentColor : "#5E5E62"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ToggleSwitch {
                        checked: appSettings.acMasterEnabled
                        onToggled: (v) => {
                            appSettings.acMasterEnabled = v
                            autoClicker.setMasterEnabled(v)
                            if (!v) autoClicker.setRunning(false)
                        }
                    }
                }
            }

            // Status display
            GlassCard {
                Layout.fillWidth: true
                height: 120

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 52; height: 52

                        Rectangle {
                            anchors.centerIn: parent
                            width: 52; height: 52; radius: 26
                            color: "transparent"
                            border.width: 2
                            border.color: autoClicker.running ? "#32D74B" : "#3A3A3A"
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 52; height: 52; radius: 26
                            color: "transparent"
                            border.width: 3
                            border.color: autoClicker.running ? appSettings.accentColor : "transparent"
                            visible: autoClicker.running

                            RotationAnimator on rotation {
                                running: autoClicker.running && appSettings.animationsEnabled
                                from: 0; to: 360
                                duration: 1200
                                loops: Animation.Infinite
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "◎"; font.pixelSize: 22
                            color: autoClicker.running ? "#32D74B" : "#5E5E62"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !appSettings.acMasterEnabled ? "DISABLED"
                              : autoClicker.running ? "CLICKING" : "IDLE"
                        font { pixelSize: 12; weight: Font.Bold; letterSpacing: 1.5 }
                        color: !appSettings.acMasterEnabled ? "#3A3A3A"
                               : autoClicker.running ? "#32D74B" : "#5E5E62"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            // Start / Stop button
            AnimButton {
                Layout.fillWidth: true
                height: 38
                text: autoClicker.running ? "  Stop  " : "  Start  "
                primary: !autoClicker.running && appSettings.acMasterEnabled
                danger:   autoClicker.running
                radius: 10
                enabled: appSettings.acMasterEnabled
                opacity: appSettings.acMasterEnabled ? 1.0 : 0.35
                Behavior on opacity { NumberAnimation { duration: 150 } }
                onClicked: autoClicker.setRunning(!autoClicker.running)
            }

            // CPS display card
            GlassCard {
                Layout.fillWidth: true
                height: 76

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 4

                    RowLayout {
                        Text { text: "CPS"; font.pixelSize: 11; color: "#8E8E93"; font.weight: Font.Medium }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: appSettings.acCPS.toFixed(1)
                            font { pixelSize: 20; weight: Font.Bold }
                            color: appSettings.accentColor
                        }
                    }

                    ModernSlider {
                        Layout.fillWidth: true
                        from: 1; to: 100; stepSize: 0.5
                        value: appSettings.acCPS
                        onValueChanged: {
                            appSettings.acCPS = value
                            autoClicker.setCPS(value)
                        }
                    }
                }
            }

            // Hotkey + Mode card
            GlassCard {
                Layout.fillWidth: true
                height: 136

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    SectionLabel { text: "HOTKEY & TRIGGER MODE" }

                    RowLayout {
                        spacing: 10
                        Text { text: "Hotkey"; font.pixelSize: 13; color: "#8E8E93"; width: 52 }
                        HotkeyPicker {
                            hotkeyManager: acHotkey
                            currentVK: appSettings.acHotkey
                            onCurrentVKChanged: appSettings.acHotkey = currentVK
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text { text: "Mode"; font.pixelSize: 13; color: "#8E8E93"; width: 52 }

                        Repeater {
                            model: [["Toggle", 0], ["Hold", 1]]
                            delegate: Rectangle {
                                property var item: modelData
                                implicitWidth: 68; height: 26; radius: 6
                                color: appSettings.acHotkeyMode === item[1]
                                           ? Qt.rgba(Qt.color(appSettings.accentColor).r,
                                                     Qt.color(appSettings.accentColor).g,
                                                     Qt.color(appSettings.accentColor).b, 0.25)
                                           : "#1E1E1E"
                                border.color: appSettings.acHotkeyMode === item[1]
                                              ? appSettings.accentColor : "#2E2E2E"
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text {
                                    anchors.centerIn: parent; text: item[0]
                                    font { pixelSize: 12; weight: Font.Medium }
                                    color: appSettings.acHotkeyMode === item[1]
                                           ? appSettings.accentColor : "#8E8E93"
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        appSettings.acHotkeyMode = item[1]
                                        acHotkey.setMode(item[1])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ── Right: config ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // Click type
            GlassCard {
                Layout.fillWidth: true
                height: 100

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 10

                    SectionLabel { text: "CLICK TYPE" }

                    RowLayout {
                        spacing: 8

                        Repeater {
                            model: [["LMB", 0], ["RMB", 1], ["MMB", 2]]
                            delegate: Rectangle {
                                property var item: modelData
                                implicitWidth: 70; height: 32; radius: 8
                                color: appSettings.acClickType === item[1]
                                           ? appSettings.accentColor : "#252525"
                                border.color: appSettings.acClickType === item[1]
                                              ? "transparent" : "#3A3A3A"
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: item[0]
                                    font { pixelSize: 12; weight: Font.Medium }
                                    color: appSettings.acClickType === item[1] ? "#FFFFFF" : "#8E8E93"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        appSettings.acClickType = item[1]
                                        autoClicker.setClickType(item[1])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Safe Zones
            GlassCard {
                Layout.fillWidth: true
                height: 126

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 10

                    SectionLabel { text: "SAFE ZONES  (auto-pause areas)" }

                    RowLayout {
                        ToggleSwitch {
                            checked: appSettings.acSafeTaskbar
                            label:   "Pause over taskbar"
                            onToggled: (v) => {
                                appSettings.acSafeTaskbar = v
                                autoClicker.setSafeTaskbar(v)
                            }
                        }
                    }

                    RowLayout {
                        ToggleSwitch {
                            checked: appSettings.acSafeTitlebar
                            label:   "Pause over window title bars"
                            onToggled: (v) => {
                                appSettings.acSafeTitlebar = v
                                autoClicker.setSafeTitlebar(v)
                            }
                        }
                    }

                    Text {
                        text: "Safe zones prevent accidental clicks on system UI."
                        font.pixelSize: 11; color: "#5E5E62"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
