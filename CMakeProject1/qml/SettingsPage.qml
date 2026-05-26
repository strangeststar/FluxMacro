import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "./components"

Item {
    id: root

    ScrollView {
        anchors { fill: parent; margins: 20 }
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: parent.width
            spacing: 14

            // ── Appearance ────────────────────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                height: 140

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 12

                    SectionLabel { text: "APPEARANCE" }

                    RowLayout {
                        spacing: 12

                        Text { text: "Accent color"; font.pixelSize: 13; color: "#CFCFCF"; width: 110 }

                        // Emo / death-metal inspired palette — Blood Red is default
                        Repeater {
                            model: [
                                { color: "#B00020", name: "Blood"      },
                                { color: "#7A0000", name: "Abyss"      },
                                { color: "#FF2200", name: "Hellfire"   },
                                { color: "#C8A800", name: "Relic Gold" },
                                { color: "#7A00AA", name: "Ritual"     },
                                { color: "#0A84FF", name: "Electric"   },
                                { color: "#1A8A30", name: "Plague"     },
                                { color: "#FF8C00", name: "Ember"      },
                                { color: "#00C0C0", name: "Venom"      },
                                { color: "#FFB6C1", name: "Baby Pink"  },
                                { color: "#E8E8EE", name: "Mono"       }
                            ]
                            delegate: Rectangle {
                                width: 26; height: 26; radius: 13
                                color: modelData.color
                                border.color: appSettings.accentColor === modelData.color ? "#FFFFFF" : "transparent"
                                border.width: 2
                                scale: ma2.containsMouse ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                                ToolTip.visible: ma2.containsMouse
                                ToolTip.text: modelData.name
                                ToolTip.delay: 400
                                MouseArea {
                                    id: ma2; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: appSettings.accentColor = modelData.color
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 12
                        Text { text: "Animations"; font.pixelSize: 13; color: "#CFCFCF"; width: 110 }
                        ToggleSwitch {
                            checked: appSettings.animationsEnabled
                            onToggled: (v) => appSettings.animationsEnabled = v
                        }
                        Text {
                            text: "Disable for better performance"
                            font.pixelSize: 11; color: "#5E5E62"
                        }
                    }
                }
            }

            // ── Macro hotkey ──────────────────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                height: 148

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 12

                    SectionLabel { text: "MACRO HOTKEY" }

                    RowLayout {
                        spacing: 10
                        Text { text: "Hotkey"; font.pixelSize: 13; color: "#8E8E93"; width: 70 }
                        HotkeyPicker {
                            hotkeyManager: macroHotkey
                            currentVK: appSettings.macroHotkey
                            onCurrentVKChanged: appSettings.macroHotkey = currentVK
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text { text: "Mode"; font.pixelSize: 13; color: "#8E8E93"; width: 70 }

                        Repeater {
                            model: [["Toggle", 0], ["Hold", 1]]
                            delegate: Rectangle {
                                property var item: modelData
                                implicitWidth: 72; height: 28; radius: 6
                                color: appSettings.macroHotkeyMode === item[1]
                                           ? Qt.rgba(Qt.color(appSettings.accentColor).r,
                                                     Qt.color(appSettings.accentColor).g,
                                                     Qt.color(appSettings.accentColor).b, 0.25)
                                           : "#1E1E1E"
                                border.color: appSettings.macroHotkeyMode === item[1]
                                              ? appSettings.accentColor : "#2E2E2E"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent; text: item[0]
                                    font { pixelSize: 12; weight: Font.Medium }
                                    color: appSettings.macroHotkeyMode === item[1]
                                           ? appSettings.accentColor : "#8E8E93"
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        appSettings.macroHotkeyMode = item[1]
                                        macroHotkey.setMode(item[1])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── AutoClicker hotkey ────────────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                height: 148

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 12

                    SectionLabel { text: "AUTOCLICKER HOTKEY" }

                    RowLayout {
                        spacing: 10
                        Text { text: "Hotkey"; font.pixelSize: 13; color: "#8E8E93"; width: 70 }
                        HotkeyPicker {
                            hotkeyManager: acHotkey
                            currentVK: appSettings.acHotkey
                            onCurrentVKChanged: appSettings.acHotkey = currentVK
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text { text: "Mode"; font.pixelSize: 13; color: "#8E8E93"; width: 70 }

                        Repeater {
                            model: [["Toggle", 0], ["Hold", 1]]
                            delegate: Rectangle {
                                property var item: modelData
                                implicitWidth: 72; height: 28; radius: 6
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

            // ── Reset ─────────────────────────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                height: 90

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 10

                    SectionLabel { text: "RESET" }

                    RowLayout {
                        spacing: 12

                        AnimButton {
                            text: "Restore Default Settings"
                            danger: true
                            onClicked: confirmReset.open()
                        }

                        Text {
                            text: "Resets all settings. Macros are preserved."
                            font.pixelSize: 11; color: "#5E5E62"
                        }
                    }
                }
            }

            // ── About ─────────────────────────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                height: 90

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 4

                    RowLayout {
                        spacing: 10
                        Text {
                            text: "FLUXMACRO"
                            font { pixelSize: 14; weight: Font.Bold; letterSpacing: 2.0 }
                            color: appSettings.accentColor
                        }
                        Text {
                            text: "v2.0"
                            font { pixelSize: 14; weight: Font.DemiBold }
                            color: "#4A4A5E"
                        }
                    }
                    Text {
                        text: "Macro sequencer & autoclicker — Windows"
                        font.pixelSize: 12; color: "#4A4A5E"
                    }
                    Text {
                        text: "Qt6 / Windows"
                        font.pixelSize: 11; color: "#2E2E3E"
                    }
                }
            }

            Item { height: 20 }
        }
    }

    // Confirm reset dialog (accessed from main.qml via confirmReset id)
    property alias confirmResetDialog: confirmReset
    Dialog {
        id: confirmReset
        title: "Restore Defaults?"
        modal: true
        x: root.width  / 2 - width  / 2
        y: root.height / 2 - height / 2
        width: 340; height: 140

        background: Rectangle {
            color: "#1C1C1C"; radius: 12
            border.color: "#3A3A3A"; border.width: 1
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
