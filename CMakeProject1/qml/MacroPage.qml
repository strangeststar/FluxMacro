import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "./components"

Item {
    id: root

    ListModel { id: macroListModel }

    property int  selectedIndex:        0
    property int  capturingActionIndex: -1
    property int  capturingMacroIndex:  -1
    property bool m_loading:            false

    // Mirrors the selected macro's 'enabled' flag as a proper QML property so
    // ToggleSwitch gets a reactive binding that survives imperative assignments.
    property bool selectedMacroEnabled: macroListModel.count > 0
                                        ? macroListModel.get(selectedIndex).enabled : true
    onSelectedIndexChanged: {
        selectedMacroEnabled = macroListModel.count > 0
                               ? macroListModel.get(selectedIndex).enabled : true
    }

    // ── Key capture results from the shared keyCapturer ───────────────────────
    Connections {
        target: keyCapturer
        function onKeyCaptured(vk, name) {
            if (root.capturingMacroIndex >= 0) {
                macroListModel.setProperty(root.capturingMacroIndex, "triggerKey", vk)
                root.capturingMacroIndex = -1
                syncToEngine()
            } else if (root.capturingActionIndex >= 0) {
                var acts = macroListModel.get(root.selectedIndex).actions
                acts.setProperty(root.capturingActionIndex, "keyCode", vk)
                acts.setProperty(root.capturingActionIndex, "keyName", name)
                root.capturingActionIndex = -1
                syncToEngine()
            }
        }
    }

    function cancelAllCapture() {
        keyCapturer.cancelCapture()
        capturingActionIndex = -1
        capturingMacroIndex  = -1
    }

    // Debounce timer — slider drags fire this repeatedly; batch the file write
    Timer {
        id: saveDebounce
        interval: 120
        repeat: false
        onTriggered: {
            var arr = []
            for (var i = 0; i < macroListModel.count; i++) {
                var m = macroListModel.get(i)
                var acts = []
                for (var j = 0; j < m.actions.count; j++) {
                    var a = m.actions.get(j)
                    acts.push({ type: a.type, keyCode: a.keyCode,
                                amount: a.amount, delayMs: a.delayMs, keyName: a.keyName })
                }
                arr.push({ name: m.name, enabled: m.enabled,
                           speed: m.speed, loopDelayMs: m.loopDelayMs,
                           useGlobalHotkey: m.useGlobalHotkey,
                           triggerKey: m.triggerKey, triggerMode: m.triggerMode,
                           isDefault: m.isDefault, actions: acts })
            }
            var jsonStr = JSON.stringify(arr)
            macroEngine.fromJsonStr(jsonStr)
            appSettings.saveMacrosStr(jsonStr)
        }
    }

    function syncToEngine() {
        if (m_loading) return
        saveDebounce.restart()
    }

    Component.onCompleted: {
        m_loading = true
        var raw = appSettings.loadMacrosStr()
        var saved = []
        try { saved = JSON.parse(raw) } catch(e) {}
        if (!Array.isArray(saved)) saved = []
        if (saved.length > 0) {
            macroEngine.fromJsonStr(JSON.stringify(saved))
            for (var i = 0; i < saved.length; i++) {
                var m = saved[i]
                var actModel = Qt.createQmlObject('import QtQuick; ListModel {}', root)
                if (m.actions) {
                    for (var j = 0; j < m.actions.length; j++) actModel.append(m.actions[j])
                }
                macroListModel.append({
                    name:            m.name            || ("Macro " + (i + 1)),
                    enabled:         m.enabled         !== undefined ? m.enabled         : true,
                    speed:           m.speed           || 1.0,
                    loopDelayMs:     m.loopDelayMs     !== undefined ? m.loopDelayMs     : 1,
                    useGlobalHotkey: m.useGlobalHotkey !== undefined ? m.useGlobalHotkey : true,
                    triggerKey:      m.triggerKey      || 0,
                    triggerMode:     m.triggerMode     !== undefined ? m.triggerMode     : 0,
                    isDefault:       m.isDefault       || false,
                    actions:         actModel
                })
            }
        } else {
            // No saved data — insert the default Scroll Spam seed
            var defModel = Qt.createQmlObject('import QtQuick; ListModel {}', root)
            defModel.append({ type: 0, keyCode: 0, amount: 120, delayMs: 5, keyName: "" })
            defModel.append({ type: 1, keyCode: 0, amount: 120, delayMs: 5, keyName: "" })
            macroListModel.append({
                name: "Scroll Spam", enabled: true, speed: 1.0, loopDelayMs: 1,
                useGlobalHotkey: true, triggerKey: 0, triggerMode: 0, isDefault: true,
                actions: defModel
            })
        }
        m_loading = false
        syncToEngine()
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    RowLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 12

        // ── Macro list ────────────────────────────────────────────────────────
        GlassCard {
            Layout.preferredWidth: 200
            Layout.fillHeight: true

            ColumnLayout {
                anchors { fill: parent; margins: 10 }
                spacing: 8

                RowLayout {
                    Text {
                        text: "MACROS"
                        font { pixelSize: 10; weight: Font.Bold; letterSpacing: 1.2 }
                        color: appSettings.accentColor
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: badge.implicitWidth + 10; height: 18; radius: 9
                        color: "#2A2A2A"
                        Text {
                            id: badge; anchors.centerIn: parent
                            text: macroListModel.count
                            font.pixelSize: 11; color: "#8E8E93"
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#2A2A2A" }

                ListView {
                    id: macroList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: macroListModel
                    clip: true; spacing: 3

                    delegate: Rectangle {
                        width: macroList.width; height: 44
                        radius: 7
                        color: root.selectedIndex === index
                               ? Qt.rgba(Qt.color(appSettings.accentColor).r,
                                         Qt.color(appSettings.accentColor).g,
                                         Qt.color(appSettings.accentColor).b, 0.18)
                               : (dHov.containsMouse ? "#222222" : "transparent")
                        Behavior on color { ColorAnimation { duration: 80 } }

                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: 3; radius: 2
                            color: root.selectedIndex === index ? appSettings.accentColor : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        Column {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            spacing: 2
                            Row {
                                spacing: 7
                                Rectangle {
                                    width: 7; height: 7; radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: model.enabled ? "#32D74B" : "#3A3A3A"
                                }
                                Text {
                                    text: model.name || ("Macro " + (index + 1))
                                    font.pixelSize: 13
                                    color: root.selectedIndex === index ? "#FFFFFF" : "#CFCFCF"
                                    elide: Text.ElideRight; width: 130
                                }
                            }
                            // Key indicator
                            Row {
                                spacing: 4; leftPadding: 14
                                Text {
                                    visible: model.isDefault
                                    text: "🔒"; font.pixelSize: 9; color: "#5E5E62"
                                }
                                Text {
                                    visible: !model.useGlobalHotkey && model.triggerKey > 0
                                    text: "[" + keyNames.nameOf(model.triggerKey) + "]"
                                    font.pixelSize: 9; color: appSettings.accentColor
                                }
                                Text {
                                    visible: model.useGlobalHotkey
                                    text: "Global"; font.pixelSize: 9; color: "#5E5E62"
                                }
                            }
                        }

                        HoverHandler { id: dHov }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.selectedIndex = index; cancelAllCapture(); root.forceActiveFocus() }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#2A2A2A" }

                AnimButton {
                    Layout.fillWidth: true; text: "+ Add Macro"
                    onClicked: {
                        var actModel = Qt.createQmlObject('import QtQuick; ListModel {}', root)
                        macroListModel.append({
                            name: "Macro " + (macroListModel.count + 1),
                            enabled: true, speed: 1.0, loopDelayMs: 1,
                            useGlobalHotkey: true, triggerKey: 0, triggerMode: 0, isDefault: false,
                            actions: actModel
                        })
                        root.selectedIndex = macroListModel.count - 1
                        cancelAllCapture()
                        syncToEngine()
                    }
                }

                AnimButton {
                    Layout.fillWidth: true; text: "Remove"; danger: true
                    // Hidden for the last macro OR any isDefault macro
                    visible: macroListModel.count > 1
                             && !(macroListModel.count > 0
                                  && macroListModel.get(root.selectedIndex).isDefault)
                    onClicked: {
                        if (macroListModel.count > 0
                                && macroListModel.get(root.selectedIndex).isDefault) return
                        cancelAllCapture()
                        macroListModel.remove(root.selectedIndex)
                        root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                        syncToEngine()
                    }
                }
            }
        }

        // ── Macro editor ──────────────────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: macroListModel.count > 0

            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                spacing: 10

                // ── Master switch row ─────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 44; radius: 8
                    color: appSettings.macroMasterEnabled
                           ? Qt.rgba(Qt.color(appSettings.accentColor).r,
                                     Qt.color(appSettings.accentColor).g,
                                     Qt.color(appSettings.accentColor).b, 0.12)
                           : "#1A1A1A"
                    border.color: appSettings.macroMasterEnabled ? appSettings.accentColor : "#2A2A2A"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        Text {
                            text: "Master Enable"
                            font { pixelSize: 13; weight: Font.Medium }
                            color: appSettings.macroMasterEnabled ? "#FFFFFF" : "#8E8E93"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: appSettings.macroMasterEnabled ? "— All enabled macros are running" : "— All macros are paused"
                            font.pixelSize: 11
                            color: appSettings.macroMasterEnabled ? appSettings.accentColor : "#5E5E62"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Item { Layout.fillWidth: true }
                        ToggleSwitch {
                            checked: appSettings.macroMasterEnabled
                            onToggled: (v) => {
                                appSettings.macroMasterEnabled = v
                                macroEngine.setMasterEnabled(v)
                            }
                        }
                    }
                }

                // ── Header row: name / enabled / global hotkey ────────────────
                RowLayout {
                    spacing: 10

                    TextField {
                        Layout.preferredWidth: 200
                        text: macroListModel.count > 0
                              ? macroListModel.get(root.selectedIndex).name : ""
                        font.pixelSize: 14; color: "#FFFFFF"
                        background: Rectangle {
                            color: "#252525"; radius: 7
                            border.color: parent.activeFocus ? appSettings.accentColor : "#3A3A3A"
                        }
                        leftPadding: 10; rightPadding: 10
                        onTextEdited: {
                            if (macroListModel.count > 0)
                                macroListModel.setProperty(root.selectedIndex, "name", text)
                        }
                        onEditingFinished: syncToEngine()
                        Keys.onReturnPressed: Qt.callLater(function() { focus = false })
                        Keys.onEscapePressed: (event) => {
                            // Revert to saved name and drop focus
                            if (macroListModel.count > 0)
                                text = macroListModel.get(root.selectedIndex).name
                            focus = false
                            event.accepted = true
                        }
                    }

                    ToggleSwitch {
                        checked: root.selectedMacroEnabled
                        label: "Enabled"
                        onToggled: (v) => {
                            root.selectedMacroEnabled = v
                            if (macroListModel.count > 0)
                                macroListModel.setProperty(root.selectedIndex, "enabled", v)
                            syncToEngine()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text { text: "Global key:"; font.pixelSize: 12; color: "#8E8E93" }
                    HotkeyPicker {
                        hotkeyManager: macroHotkey
                        currentVK: appSettings.macroHotkey
                        onCurrentVKChanged: appSettings.macroHotkey = currentVK
                    }

                    Repeater {
                        model: [["Toggle", 0], ["Hold", 1]]
                        delegate: Rectangle {
                            property var item: modelData
                            width: 60; height: 28; radius: 6
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
                                onClicked: { appSettings.macroHotkeyMode = item[1]; macroHotkey.setMode(item[1]) }
                            }
                        }
                    }
                }

                // ── Per-macro trigger row ─────────────────────────────────────
                RowLayout {
                    spacing: 8
                    visible: macroListModel.count > 0

                    Text { text: "Trigger:"; font.pixelSize: 12; color: "#8E8E93" }

                    // Global button
                    Rectangle {
                        property bool sel: macroListModel.count > 0
                                           && macroListModel.get(root.selectedIndex).useGlobalHotkey
                        width: 70; height: 28; radius: 6
                        color: sel ? Qt.rgba(Qt.color(appSettings.accentColor).r,
                                             Qt.color(appSettings.accentColor).g,
                                             Qt.color(appSettings.accentColor).b, 0.25)
                                   : "#1E1E1E"
                        border.color: sel ? appSettings.accentColor : "#2E2E2E"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "Global"
                               font { pixelSize: 12; weight: Font.Medium }
                               color: parent.sel ? appSettings.accentColor : "#8E8E93" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (macroListModel.count > 0) {
                                    cancelAllCapture()
                                    macroListModel.setProperty(root.selectedIndex, "useGlobalHotkey", true)
                                    syncToEngine()
                                }
                            }
                        }
                    }

                    // Individual button
                    Rectangle {
                        property bool sel: macroListModel.count > 0
                                           && !macroListModel.get(root.selectedIndex).useGlobalHotkey
                        width: 80; height: 28; radius: 6
                        color: sel ? Qt.rgba(Qt.color(appSettings.accentColor).r,
                                             Qt.color(appSettings.accentColor).g,
                                             Qt.color(appSettings.accentColor).b, 0.25)
                                   : "#1E1E1E"
                        border.color: sel ? appSettings.accentColor : "#2E2E2E"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "Individual"
                               font { pixelSize: 12; weight: Font.Medium }
                               color: parent.sel ? appSettings.accentColor : "#8E8E93" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (macroListModel.count > 0) {
                                    cancelAllCapture()
                                    macroListModel.setProperty(root.selectedIndex, "useGlobalHotkey", false)
                                    syncToEngine()
                                }
                            }
                        }
                    }

                    // Key bind button (only when Individual mode)
                    Rectangle {
                        property bool isIndiv: macroListModel.count > 0
                                               && !macroListModel.get(root.selectedIndex).useGlobalHotkey
                        property bool capturing: capturingMacroIndex === root.selectedIndex

                        visible: isIndiv
                        implicitWidth: mkLabel.implicitWidth + 32; height: 28; radius: 6
                        color: capturing ? "#2A2200" : (mkHov.containsMouse ? "#252525" : "#1E1E1E")
                        border.color: capturing ? "#FFD60A" : "#3A3A3A"
                        border.width: capturing ? 2 : 1
                        Behavior on color { ColorAnimation { duration: 80 } }

                        SequentialAnimation on opacity {
                            running: parent.capturing && appSettings.animationsEnabled
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.5; duration: 400 }
                            NumberAnimation { to: 1.0; duration: 400 }
                        }

                        Text {
                            id: mkLabel; anchors.centerIn: parent
                            text: parent.capturing ? "Press any key…"
                                  : (macroListModel.count > 0
                                     && macroListModel.get(root.selectedIndex).triggerKey > 0
                                     ? "[ " + keyNames.nameOf(macroListModel.get(root.selectedIndex).triggerKey) + " ]"
                                     : "Click to bind")
                            font.pixelSize: 12
                            color: parent.capturing ? "#FFD60A" : "#CFCFCF"
                        }
                        HoverHandler { id: mkHov }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (capturingMacroIndex === root.selectedIndex) {
                                    cancelAllCapture()
                                } else {
                                    cancelAllCapture()
                                    capturingMacroIndex = root.selectedIndex
                                    keyCapturer.beginCapture()
                                }
                            }
                        }
                    }

                    // Hold / Toggle mode (visible when Individual trigger is selected)
                    Row {
                        spacing: 4
                        visible: macroListModel.count > 0
                                 && !macroListModel.get(root.selectedIndex).useGlobalHotkey

                        Repeater {
                            model: [["Hold", 0], ["Toggle", 1]]
                            delegate: Rectangle {
                                property bool sel: macroListModel.count > 0
                                                   && macroListModel.get(root.selectedIndex).triggerMode === modelData[1]
                                width: 60; height: 28; radius: 6
                                color: sel ? Qt.rgba(Qt.color(appSettings.accentColor).r,
                                                     Qt.color(appSettings.accentColor).g,
                                                     Qt.color(appSettings.accentColor).b, 0.25)
                                           : "#1E1E1E"
                                border.color: sel ? appSettings.accentColor : "#2E2E2E"
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text {
                                    anchors.centerIn: parent; text: modelData[0]
                                    font { pixelSize: 12; weight: Font.Medium }
                                    color: parent.sel ? appSettings.accentColor : "#8E8E93"
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (macroListModel.count > 0) {
                                            macroListModel.setProperty(root.selectedIndex, "triggerMode", modelData[1])
                                            syncToEngine()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: macroListModel.count > 0
                                 && macroListModel.get(root.selectedIndex).useGlobalHotkey
                        text: "Triggers with the global key above"
                        font.pixelSize: 11; color: "#5E5E62"
                    }
                }

                // ── Speed + Loop delay ────────────────────────────────────────
                RowLayout {
                    spacing: 16

                    RowLayout {
                        spacing: 8
                        Text { text: "Speed"; font.pixelSize: 12; color: "#8E8E93" }
                        ModernSlider {
                            width: 160; from: 0.1; to: 20; stepSize: 0.1
                            value: macroListModel.count > 0
                                   ? macroListModel.get(root.selectedIndex).speed : 1.0
                            onValueChanged: {
                                if (macroListModel.count > 0)
                                    macroListModel.setProperty(root.selectedIndex, "speed", value)
                                syncToEngine()
                            }
                        }
                        Text {
                            text: macroListModel.count > 0
                                  ? macroListModel.get(root.selectedIndex).speed.toFixed(1) + "x" : "1.0x"
                            font.pixelSize: 12; color: appSettings.accentColor; width: 36
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text { text: "Loop delay (ms)"; font.pixelSize: 12; color: "#8E8E93" }
                        Rectangle {
                            width: 70; height: 28; radius: 6
                            color: "#252525"; border.color: "#3A3A3A"
                            TextInput {
                                anchors { fill: parent; margins: 6 }
                                text: macroListModel.count > 0
                                      ? macroListModel.get(root.selectedIndex).loopDelayMs : 1
                                font.pixelSize: 13; color: "#FFFFFF"
                                validator: IntValidator { bottom: 0; top: 9999 }
                                onEditingFinished: {
                                    if (macroListModel.count > 0)
                                        macroListModel.setProperty(root.selectedIndex,
                                            "loopDelayMs", parseInt(text) || 0)
                                    syncToEngine()
                                }
                                Keys.onReturnPressed: Qt.callLater(function() { focus = false })
                                Keys.onEscapePressed: (event) => { focus = false; event.accepted = true }
                            }
                        }
                    }
                }

                SectionLabel { text: "ACTIONS  (sequence loops while running)" }

                // ── Actions table ─────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: "#151515"; radius: 8; clip: true

                    Rectangle {
                        id: tableHeader
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 30; color: "#1A1A1A"; radius: 8

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 1; color: "#2A2A2A"
                        }

                        Row {
                            anchors { fill: parent; leftMargin: 10 }
                            spacing: 0

                            Repeater {
                                model: [
                                    { label: "#",          w: 32  },
                                    { label: "Action",     w: 160 },
                                    { label: "Amount",     w: 80  },
                                    { label: "Delay (ms)", w: 90  },
                                    { label: "Key Bind",   w: -1  },
                                    { label: "",           w: 52  }
                                ]
                                delegate: Item {
                                    width: modelData.w < 0
                                           ? tableBody.width - 32 - 160 - 80 - 90 - 52 - 10
                                           : modelData.w
                                    height: tableHeader.height
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font { pixelSize: 10; weight: Font.Bold; letterSpacing: 0.8 }
                                        color: "#5E5E62"
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        id: tableBody
                        anchors {
                            top: tableHeader.bottom; left: parent.left
                            right: parent.right; bottom: parent.bottom
                        }
                        clip: true

                        model: macroListModel.count > 0
                               ? macroListModel.get(root.selectedIndex).actions : null

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle { color: "#3A3A3A"; radius: 3 }
                        }

                        delegate: Rectangle {
                            width: tableBody.width; height: 38
                            color: index % 2 === 0 ? "#161616" : "#181818"

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 1; color: "#222222"
                            }

                            Row {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 4 }
                                spacing: 0

                                // # / move-up
                                Item {
                                    width: 32; height: parent.height
                                    Text {
                                        anchors.centerIn: parent
                                        text: index > 0 ? "↑" : (index + 1)
                                        font.pixelSize: index > 0 ? 16 : 11
                                        color: index > 0 ? "#8E8E93" : "#5E5E62"
                                    }
                                    MouseArea {
                                        anchors.fill: parent; visible: index > 0
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var acts = macroListModel.get(root.selectedIndex).actions
                                            acts.move(index, index - 1, 1)
                                            syncToEngine()
                                        }
                                    }
                                }

                                // Action type
                                Item {
                                    width: 160; height: parent.height
                                    ComboBox {
                                        anchors { left: parent.left; right: parent.right; margins: 2; verticalCenter: parent.verticalCenter }
                                        height: 28
                                        model: ["Scroll Up","Scroll Down","Left Click","Right Click",
                                                "Middle Click","Key Press","Delay"]
                                        currentIndex: type; font.pixelSize: 12

                                        background: Rectangle {
                                            color: "#252525"; radius: 6
                                            border.color: parent.activeFocus ? appSettings.accentColor : "#3A3A3A"
                                        }
                                        contentItem: Text {
                                            leftPadding: 8; text: parent.displayText
                                            font.pixelSize: 12; color: "#CFCFCF"
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        popup.background: Rectangle { color: "#252525"; radius: 8; border.color: "#3A3A3A" }

                                        onCurrentIndexChanged: {
                                            var acts = macroListModel.get(root.selectedIndex).actions
                                            acts.setProperty(index, "type", currentIndex)
                                            syncToEngine()
                                        }
                                    }
                                }

                                // Amount (scroll only)
                                Item {
                                    width: 80; height: parent.height
                                    visible: type === 0 || type === 1
                                    Rectangle {
                                        anchors { fill: parent; margins: 3 }
                                        color: "#252525"; radius: 6; border.color: "#3A3A3A"
                                        TextInput {
                                            anchors { fill: parent; margins: 5 }
                                            text: amount; font.pixelSize: 12; color: "#CFCFCF"
                                            validator: IntValidator { bottom: 1; top: 9999 }
                                            onEditingFinished: {
                                                var acts = macroListModel.get(root.selectedIndex).actions
                                                acts.setProperty(index, "amount", parseInt(text) || 120)
                                                syncToEngine()
                                            }
                                            Keys.onReturnPressed: Qt.callLater(function() { focus = false })
                                            Keys.onEscapePressed: (event) => { focus = false; event.accepted = true }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: !(type === 0 || type === 1)
                                        text: "--"; color: "#3A3A3A"; font.pixelSize: 12
                                    }
                                }

                                // Delay
                                Item {
                                    width: 90; height: parent.height
                                    Rectangle {
                                        anchors { fill: parent; margins: 3 }
                                        color: "#252525"; radius: 6; border.color: "#3A3A3A"
                                        TextInput {
                                            anchors { fill: parent; margins: 5 }
                                            text: delayMs; font.pixelSize: 12; color: "#CFCFCF"
                                            validator: IntValidator { bottom: 0; top: 99999 }
                                            onEditingFinished: {
                                                var acts = macroListModel.get(root.selectedIndex).actions
                                                acts.setProperty(index, "delayMs", parseInt(text) || 0)
                                                syncToEngine()
                                            }
                                            Keys.onReturnPressed: Qt.callLater(function() { focus = false })
                                            Keys.onEscapePressed: (event) => { focus = false; event.accepted = true }
                                        }
                                    }
                                }

                                // Key bind (KeyPress only) — uses keyCapturer with debounce
                                Item {
                                    width: tableBody.width - 32 - 160 - 80 - 90 - 52 - 10
                                    height: parent.height

                                    property bool capturing: capturingActionIndex === index

                                    Rectangle {
                                        anchors { fill: parent; margins: 3 }
                                        visible: type === 5
                                        color: parent.capturing ? "#2A2200" : (kbHov.containsMouse ? "#252525" : "#1E1E1E")
                                        radius: 6
                                        border.color: parent.capturing ? "#FFD60A" : "#3A3A3A"
                                        border.width: parent.capturing ? 2 : 1
                                        Behavior on color { ColorAnimation { duration: 80 } }

                                        SequentialAnimation on opacity {
                                            running: parent.parent.capturing && appSettings.animationsEnabled
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.5; duration: 400 }
                                            NumberAnimation { to: 1.0; duration: 400 }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.parent.capturing ? "Press any key…"
                                                  : (keyCode > 0 ? keyName || keyNames.nameOf(keyCode) : "Click to bind")
                                            font.pixelSize: 12
                                            color: parent.parent.capturing ? "#FFD60A" : "#CFCFCF"
                                        }

                                        HoverHandler { id: kbHov }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (capturingActionIndex === index) {
                                                    cancelAllCapture()
                                                } else {
                                                    cancelAllCapture()
                                                    capturingActionIndex = index
                                                    keyCapturer.beginCapture()
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: type !== 5; text: "--"
                                        color: "#3A3A3A"; font.pixelSize: 12
                                    }
                                }

                                // Delete
                                Item {
                                    width: 52; height: parent.height
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 42; height: 26; radius: 6
                                        color: delHov.containsMouse ? "#3A1515" : "transparent"
                                        border.color: delHov.containsMouse ? "#FF453A" : "#2E2E2E"
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                        Text { anchors.centerIn: parent; text: "Del"; font.pixelSize: 11; color: "#FF453A" }
                                        HoverHandler { id: delHov }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                cancelAllCapture()
                                                macroListModel.get(root.selectedIndex).actions.remove(index)
                                                syncToEngine()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Quick-add row ─────────────────────────────────────────────
                RowLayout {
                    spacing: 6
                    Text { text: "Quick add:"; font.pixelSize: 12; color: "#5E5E62" }

                    Repeater {
                        model: [
                            ["↑ Scroll", 0, 120, 5], ["↓ Scroll", 1, 120, 5],
                            ["LMB", 2, 0, 10],        ["RMB", 3, 0, 10],
                            ["MMB", 4, 0, 10],        ["Key", 5, 0, 10],
                            ["Delay", 6, 0, 100]
                        ]
                        delegate: Rectangle {
                            property var item: modelData
                            height: 26; width: qaTxt.implicitWidth + 16; radius: 6
                            color: qaHov.containsMouse ? "#282828" : "#1E1E1E"
                            border.color: "#2E2E2E"
                            Behavior on color { ColorAnimation { duration: 80 } }
                            Text { id: qaTxt; anchors.centerIn: parent; text: item[0]; font.pixelSize: 12; color: "#CFCFCF" }
                            HoverHandler { id: qaHov }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (macroListModel.count === 0) return
                                    macroListModel.get(root.selectedIndex).actions.append({
                                        type: item[1], keyCode: 0,
                                        amount: item[2], delayMs: item[3], keyName: ""
                                    })
                                    syncToEngine()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
