import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "./components"

Item {
    id: root

    // Redraw graphs whenever history updates
    Connections {
        target: sysMonitor
        function onCpuHistoryChanged()    { procCpuGraph.requestPaint() }
        function onSysCpuHistoryChanged() { sysCpuGraph.requestPaint()  }
        function onRamHistoryChanged()    { ramGraph.requestPaint()      }
    }

    // ── Graph draw helper (shared by all Canvas elements) ─────────────────────
    function drawGraph(ctx, history, lineColor, w, h, maxVal) {
        ctx.clearRect(0, 0, w, h)

        // Dark fill
        ctx.fillStyle = "#0A0A0F"
        ctx.fillRect(0, 0, w, h)

        // Horizontal grid lines (25 / 50 / 75 %)
        ctx.lineWidth = 1
        for (var g = 1; g <= 3; g++) {
            var gy = h * g / 4
            ctx.strokeStyle = "#1C1C28"
            ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(w, gy); ctx.stroke()
        }

        if (history.length < 2) return

        var step = w / (history.length - 1)

        // Gradient fill under line
        ctx.beginPath()
        ctx.moveTo(0, h)
        for (var i = 0; i < history.length; i++) {
            var px = i * step
            var py = h - Math.min(1, history[i] / maxVal) * (h - 2)
            ctx.lineTo(px, py)
        }
        ctx.lineTo(w, h)
        ctx.closePath()
        var grad = ctx.createLinearGradient(0, 0, 0, h)
        grad.addColorStop(0, lineColor + "55")
        grad.addColorStop(1, lineColor + "00")
        ctx.fillStyle = grad
        ctx.fill()

        // Line
        ctx.beginPath()
        for (var j = 0; j < history.length; j++) {
            var lx = j * step
            var ly = h - Math.min(1, history[j] / maxVal) * (h - 2)
            if (j === 0) ctx.moveTo(lx, ly)
            else         ctx.lineTo(lx, ly)
        }
        ctx.strokeStyle = lineColor
        ctx.lineWidth = 1.5
        ctx.stroke()

        // Current value dot
        var lastIdx = history.length - 1
        var dotX = lastIdx * step
        var dotY = h - Math.min(1, history[lastIdx] / maxVal) * (h - 2)
        ctx.beginPath()
        ctx.arc(dotX, dotY, 3, 0, 2 * Math.PI)
        ctx.fillStyle = lineColor
        ctx.fill()
    }

    ColumnLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 12

        // ── Top stat cards ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [
                    { label: "APP CPU",      value: sysMonitor.procCpu.toFixed(1) + "%",       sub: "process" },
                    { label: "APP RAM",      value: sysMonitor.procRamMB.toFixed(1) + " MB",   sub: "working set" },
                    { label: "SYSTEM CPU",   value: sysMonitor.sysCpu.toFixed(1) + "%",         sub: "all cores" },
                    { label: "SYSTEM RAM",   value: (sysMonitor.sysRamUsedMB / 1024).toFixed(1) + " GB",
                                             sub:   "/ " + (sysMonitor.sysRamTotalMB / 1024).toFixed(1) + " GB total" }
                ]
                delegate: GlassCard {
                    Layout.fillWidth: true
                    height: 76

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 3

                        Text {
                            text: modelData.label
                            font { pixelSize: 9; weight: Font.Bold; letterSpacing: 1.2 }
                            color: "#4A4A5A"
                        }
                        Text {
                            text: modelData.value
                            font { pixelSize: 22; weight: Font.Bold }
                            color: appSettings.accentColor
                        }
                        Text {
                            text: modelData.sub
                            font.pixelSize: 10
                            color: "#3A3A4A"
                        }
                    }
                }
            }
        }

        // ── App Process CPU graph ─────────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                spacing: 6

                RowLayout {
                    Text {
                        text: "APP PROCESS CPU"
                        font { pixelSize: 9; weight: Font.Bold; letterSpacing: 1.2 }
                        color: "#4A4A5A"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: sysMonitor.procCpu.toFixed(2) + "%"
                        font { pixelSize: 12; weight: Font.Bold }
                        color: appSettings.accentColor
                    }
                }

                Canvas {
                    id: procCpuGraph
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onPaint: root.drawGraph(getContext("2d"),
                        sysMonitor.cpuHistory, appSettings.accentColor,
                        width, height, 100)
                }
            }
        }

        // ── Bottom row: System CPU + App RAM ──────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // System CPU graph
            GlassCard {
                Layout.fillWidth: true
                height: 160

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 6

                    RowLayout {
                        Text {
                            text: "SYSTEM CPU"
                            font { pixelSize: 9; weight: Font.Bold; letterSpacing: 1.2 }
                            color: "#4A4A5A"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: sysMonitor.sysCpu.toFixed(1) + "%"
                            font { pixelSize: 12; weight: Font.Bold }
                            color: "#6060CC"
                        }
                    }

                    Canvas {
                        id: sysCpuGraph
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        onPaint: root.drawGraph(getContext("2d"),
                            sysMonitor.sysCpuHistory, "#6060CC",
                            width, height, 100)
                    }
                }
            }

            // App RAM graph
            GlassCard {
                Layout.fillWidth: true
                height: 160

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 6

                    RowLayout {
                        Text {
                            text: "APP MEMORY"
                            font { pixelSize: 9; weight: Font.Bold; letterSpacing: 1.2 }
                            color: "#4A4A5A"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: sysMonitor.procRamMB.toFixed(1) + " MB"
                            font { pixelSize: 12; weight: Font.Bold }
                            color: "#20A060"
                        }
                    }

                    Canvas {
                        id: ramGraph
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        property real ramMax: {
                            var mx = 32
                            var h = sysMonitor.ramHistory
                            for (var i = 0; i < h.length; i++) if (h[i] > mx) mx = h[i]
                            return mx * 1.25
                        }
                        onPaint: root.drawGraph(getContext("2d"),
                            sysMonitor.ramHistory, "#20A060",
                            width, height, ramMax)
                    }
                }
            }

            // System RAM bar
            GlassCard {
                width: 140
                height: 160

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    Text {
                        text: "SYS RAM"
                        font { pixelSize: 9; weight: Font.Bold; letterSpacing: 1.2 }
                        color: "#4A4A5A"
                    }

                    Item { Layout.fillHeight: true }

                    // Vertical bar
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28
                        height: 80
                        color: "#0A0A0F"
                        radius: 4
                        border.color: "#1C1C28"

                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 2 }
                            radius: 3
                            height: {
                                var total = sysMonitor.sysRamTotalMB
                                if (total <= 0) return 0
                                return (sysMonitor.sysRamUsedMB / total) * (parent.height - 4)
                            }
                            Behavior on height { NumberAnimation { duration: 400 } }
                            color: {
                                var pct = sysMonitor.sysRamTotalMB > 0
                                    ? sysMonitor.sysRamUsedMB / sysMonitor.sysRamTotalMB : 0
                                if (pct > 0.85) return "#CC2020"
                                if (pct > 0.65) return "#C8A000"
                                return "#20A060"
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: (sysMonitor.sysRamUsedMB / 1024).toFixed(1) + "\nof " +
                              (sysMonitor.sysRamTotalMB / 1024).toFixed(0) + " GB"
                        font.pixelSize: 10
                        color: "#6A6A7A"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
