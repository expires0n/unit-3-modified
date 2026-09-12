import QtQuick
import Quickshell
import Quickshell.Io

// ─────────────────────────────────────────────────────────────
//  TIMER POPUP — bardan fırlayan küçük panel (zenity yok)
//  Presetler + custom süre + kronometre. Seçim yapınca kapatır.
// ─────────────────────────────────────────────────────────────
Item {
    id: root
    implicitWidth: 300
    implicitHeight: mainCol.implicitHeight + 20

    property bool shown: false
    property string statusText: "TMR --:--"

    function toggle() { root.shown = !root.shown }
    function hide() { root.shown = false; customInput.text = "" }
    function show() { root.shown = true }

    onShownChanged: if (shown) customInput.forceActiveFocus()

    // ── actions (state dosyasını yazar, bar okur) ──
    Process { id: actProc; property string cmd: ""; command: ["sh","-c",cmd]; running: false }
    function runCmd(c) { actProc.cmd = c; actProc.running = true }
    function startDown(secs) {
        runCmd("rm -f /tmp/unit3-timer-done; { echo MODE=down; echo END=$(( $(date +%s) + " + secs + " )); } > /tmp/unit3-timer")
        root.hide()
    }
    function startUp() {
        runCmd("rm -f /tmp/unit3-timer-done; { echo MODE=up; echo START=$(date +%s); } > /tmp/unit3-timer")
        root.hide()
    }
    function stopAll() {
        runCmd("rm -f /tmp/unit3-timer /tmp/unit3-timer-done")
        root.hide()
    }

    function parseCustom(s) {
        s = s.toLowerCase().replace(/\s+/g, "")
        if (s === "") return -1
        if (/^[0-9]+$/.test(s)) return parseInt(s) * 60
        var h = 0, m = 0, sec = 0, mt
        mt = s.match(/([0-9]+)h/); if (mt) h = parseInt(mt[1])
        mt = s.match(/([0-9]+)m/); if (mt) m = parseInt(mt[1])
        mt = s.match(/([0-9]+)s/); if (mt) sec = parseInt(mt[1])
        var t = h * 3600 + m * 60 + sec
        return t > 0 ? Math.min(t, 86400) : -1
    }
    function submitCustom() {
        var secs = parseCustom(customInput.text)
        if (secs > 0) startDown(secs)
    }

    // ── durum yoklaması (açıkken) ──
    Process {
        id: stProc
        command: ["sh","-c","cat /tmp/unit3-timer 2>/dev/null; echo \"TS=$(date +%s)\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var mode = "", val = 0, now = 0
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i].trim()
                    if (l.indexOf("MODE=") === 0) mode = l.slice(5)
                    else if (l.indexOf("END=") === 0) val = parseInt(l.slice(4))
                    else if (l.indexOf("START=") === 0) val = parseInt(l.slice(6))
                    else if (l.indexOf("TS=") === 0) now = parseInt(l.slice(3))
                }
                if (mode === "down") {
                    var r = val - now
                    if (r <= 0) root.statusText = "TMR DONE"
                    else if (r >= 3600) root.statusText = "TMR " + Math.floor(r / 3600) + "h " + String(Math.floor((r % 3600) / 60)).padStart(2, "0") + "m"
                    else root.statusText = "TMR " + String(Math.floor(r / 60)).padStart(2, "0") + ":" + String(r % 60).padStart(2, "0")
                } else if (mode === "up") {
                    var e = Math.min(Math.max(0, now - val), 86400)
                    root.statusText = "SW " + String(Math.floor(e / 3600)).padStart(2, "0") + ":" + String(Math.floor((e % 3600) / 60)).padStart(2, "0") + ":" + String(e % 60).padStart(2, "0")
                } else root.statusText = "TMR --:--"
            }
        }
    }
    Timer { interval: 1000; running: root.shown; repeat: true; onTriggered: stProc.running = true }

    // ── görünüm ──
    Rectangle {
        anchors.fill: parent
        visible: root.shown
        color: Qt.rgba(20/255, 16/255, 29/255, 0.96)
        border.color: Qt.rgba(216/255,205/255,245/255,0.25)
        border.width: 1

        Column {
            id: mainCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 8

            // başlık
            Item {
                width: parent.width; height: 18
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: "TIMER"; font.family: "SF Mono"; font.pixelSize: 10; font.letterSpacing: 3
                    color: "#D8CDF5"
                }
                Row {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.statusText; font.family: "SF Mono"; font.pixelSize: 10
                        color: Qt.rgba(216/255,205/255,245/255,0.7)
                    }
                    Item {
                        width: 18; height: 18
                        Text {
                            anchors.centerIn: parent; text: "×"; font.pixelSize: 14
                            color: Qt.rgba(216/255,205/255,245/255,0.5)
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.hide() }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(216/255,205/255,245/255,0.12) }

            // presetler
            Row {
                width: parent.width; spacing: 8
                TBtn { label: "POMO"; sub: "25m"; onClicked: root.startDown(1500) }
                TBtn { label: "1H"; sub: "60m"; onClicked: root.startDown(3600) }
                TBtn { label: "2H"; sub: "120m"; onClicked: root.startDown(7200) }
            }

            // custom
            Row {
                width: parent.width; spacing: 8
                Rectangle {
                    width: parent.width - 80; height: 34
                    color: "transparent"
                    border.width: 1
                    border.color: customInput.activeFocus ? "#D8CDF5" : Qt.rgba(216/255,205/255,245/255,0.25)
                    TextInput {
                        id: customInput
                        anchors { fill: parent; margins: 7 }
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "SF Mono"; font.pixelSize: 11
                        color: "#D8CDF5"; cursorVisible: activeFocus
                        Keys.onReturnPressed: root.submitCustom()
                        Keys.onEscapePressed: root.hide()
                        Text {
                            visible: parent.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "12h39m..."; font.family: "SF Mono"; font.pixelSize: 11; font.italic: true
                            color: Qt.rgba(216/255,205/255,245/255,0.35)
                        }
                    }
                }
                TBtn { width: 72; label: "SET"; sub: "kur"; onClicked: root.submitCustom() }
            }

            // kronometre + durdur
            Row {
                width: parent.width; spacing: 8
                TBtn { width: 196; label: "KRONOMETRE"; sub: "0'dan say"; onClicked: root.startUp() }
                TBtn { width: 76; label: "STOP"; sub: "sıfırla"; danger: true; onClicked: root.stopAll() }
            }
        }
    }

    // ── buton ──
    component TBtn: Rectangle {
        id: btnRoot
        property string label: ""
        property string sub: ""
        property bool danger: false
        signal clicked
        width: 88; height: 40
        color: btnMA.containsMouse ? Qt.rgba(216/255,205/255,245/255,0.12) : "transparent"
        border.width: 1
        border.color: btnMA.containsMouse ? (btnRoot.danger ? "#A78BFA" : "#D8CDF5") : Qt.rgba(216/255,205/255,245/255,0.25)
        Behavior on color { ColorAnimation { duration: 120 } }
        Column {
            anchors.centerIn: parent; spacing: 1
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btnRoot.label; font.family: "SF Mono"; font.pixelSize: 10; font.letterSpacing: 1
                color: btnRoot.danger ? "#A78BFA" : "#D8CDF5"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btnRoot.sub; font.family: "SF Mono"; font.pixelSize: 8
                color: Qt.rgba(216/255,205/255,245/255,0.5)
            }
        }
        MouseArea { id: btnMA; anchors.fill: parent; hoverEnabled: true; onClicked: btnRoot.clicked() }
    }
}
