import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "widgets"
import "components"
import "settings"

ShellRoot {
    id: root

    // ── NOTIFICATIONS ──
    Notifications {}

    // ── CONTROLCENTER ──
    ControlCenter {}


    // ── VOLUMEBAR ──
    VolumeBar {}

    // ── PLAYERCTL ──
    property bool   playerVisible: false
    property bool   playerOnTop:   false
    property string mpTitle:    "END OF EVANGELION"
    property string mpArtist:   "NEON GENESIS // ANNO"
    property string mpCoverUrl: ""
    property bool   mpPlaying:  false
    property real   mpPosition: 0
    property real   mpLength:   341

    // ── PLAYER fullscreen engeli ── fullscreen pencere varken panel tamamen gizlenir
    property bool playerBlocked: false
    Timer { interval: 500; running: true; repeat: true; onTriggered: fsCheckProc.running = true }
    Process {
        id: fsCheckProc
        command: ["sh","-c","hyprctl activewindow -j | python3 -c \"import sys,json\ntry:\n w=json.load(sys.stdin)\n print(w.get('fullscreen',0))\nexcept Exception:\n print(0)\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(this.text.trim())
                // 0=yok 1=maximize 2+=gerçek fullscreen → sadece gerçek fullscreen'de engelle
                root.playerBlocked = (!isNaN(v) && v >= 2)
            }
        }
    }

    // ── PLAYER cursor takibi (hover event'lerine güvenmeden, polling ile) ──
    // Her ekran için cursor player bölgesinde mi diye bakar: "AD:1 AD:0" formatı
    property var playerHover: ({})
    Timer { interval: 300; running: true; repeat: true; onTriggered: playerHoverProc.running = true }
    Process {
        id: playerHoverProc
        command: ["sh","-c","hyprctl cursorpos -j | python3 -c \"import sys,json,subprocess\ntry:\n p=json.load(sys.stdin)\n mons=json.loads(subprocess.check_output(['hyprctl','monitors','-j']))\n r=[]\n for m in mons:\n  ok=m['x']+m['width']-328<=p['x']<=m['x']+m['width']+8 and m['y']+int(m['height']*0.39)-8<=p['y']<=m['y']+int(m['height']*0.39)+228\n  r.append(m['name']+':'+('1' if ok else '0'))\n print(' '.join(r))\nexcept Exception:\n print('')\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var o = {}
                var parts = this.text.trim().split(" ")
                for (var i = 0; i < parts.length; i++) {
                    var kv = parts[i].split(":")
                    if (kv.length === 2) o[kv[0]] = (kv[1] === "1")
                }
                root.playerHover = o
            }
        }
    }

    Process {
        id: playerctlMeta
        command: ["playerctl","metadata","--format",
                  "{{title}}|{{artist}}|{{mpris:artUrl}}|{{status}}|{{position}}|{{mpris:length}}"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split("|")
                if (p.length >= 4) {
                    if (p[0]) root.mpTitle    = p[0]
                    if (p[1]) root.mpArtist   = p[1]
                    root.mpCoverUrl = p[2] || ""
                    root.mpPlaying  = (p[3] === "Playing")
                    root.mpPosition = parseFloat(p[4] || "0") / 1000000
                    root.mpLength   = Math.max(1, parseFloat(p[5] || "341000000") / 1000000)
                }
            }
        }
    }
    Process { id: pcPlay; command: ["playerctl","play-pause"]; running: false }
    Process { id: pcNext; command: ["playerctl","next"];       running: false }
    Process { id: pcPrev; command: ["playerctl","previous"];   running: false }
    Timer { interval:1000; running:true; repeat:true; onTriggered: playerctlMeta.running=true }

    property string currentUser: "user"
    Process {
        id: getUserProc; command:["sh","-c","echo $USER"]; running:true
        stdout: SplitParser { onRead: data => { var u=data.trim(); if(u!=="") root.currentUser=u } }
    }

    property int _lastToggle: 0; property int _lastFront: 0
    property int _lastMenu:   0
    property int _lastTimerT: 0

    Process { id:chkToggle; command:["sh","-c","wc -l < /tmp/qs-toggle 2>/dev/null || echo 0"]; running:false
        stdout:StdioCollector{ onStreamFinished:{ var n=parseInt(this.text.trim())||0; if(n!==root._lastToggle){root._lastToggle=n;root.playerVisible=!root.playerVisible} }}
    }
    Process { id:chkFront; command:["sh","-c","wc -l < /tmp/qs-front 2>/dev/null || echo 0"]; running:false
        stdout:StdioCollector{ onStreamFinished:{ var n=parseInt(this.text.trim())||0; if(n!==root._lastFront){root._lastFront=n;root.playerOnTop=!root.playerOnTop} }}
    }
    Process { id:chkMenu; command:["sh","-c","wc -l < /tmp/qs-menu 2>/dev/null || echo 0"]; running:false
        stdout:StdioCollector{ onStreamFinished:{ var n=parseInt(this.text.trim())||0; if(n!==root._lastMenu){root._lastMenu=n;detectMonitor.running=true} }}
    }
    Process { id:chkTimerT; command:["sh","-c","wc -l < /tmp/qs-timertoggle 2>/dev/null || echo 0"]; running:false
        stdout:StdioCollector{ onStreamFinished:{ var n=parseInt(this.text.trim())||0; if(n!==root._lastTimerT){root._lastTimerT=n;detectTimerMonitor.running=true} }}
    }

    Timer { interval:200; running:true; repeat:true
        onTriggered:{ chkToggle.running=true;chkFront.running=true;chkMenu.running=true;chkTimerT.running=true }
    }

    Component.onCompleted: {
        Qt.createQmlObject(
            'import Quickshell.Io; Process{command:["sh","-c","rm -f /tmp/qs-menu /tmp/qs-toggle /tmp/qs-front /tmp/qs-timertoggle"];running:true}',
            root, "cleanup")
    }

    property string menuActiveMonitor: Quickshell.screens.length>0 ? Quickshell.screens[0].name : ""
    signal menuFireToggle()

    Process {
        id: detectMonitor
        command: ["/bin/sh", Qt.resolvedUrl("active-monitor.sh").toString().replace("file://","")]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var name = this.text.trim()
                if (name !== "") root.menuActiveMonitor = name
                root.menuFireToggle()
            }
        }
    }

    property string timerActiveMonitor: Quickshell.screens.length>0 ? Quickshell.screens[0].name : ""
    signal timerFireToggle()

    Process {
        id: detectTimerMonitor
        command: ["/bin/sh", Qt.resolvedUrl("active-monitor.sh").toString().replace("file://","")]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var name = this.text.trim()
                if (name !== "") root.timerActiveMonitor = name
                root.timerFireToggle()
            }
        }
    }






    // ── MENU ──
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen:modelData
            anchors.top:true;anchors.left:true;anchors.right:true;anchors.bottom:true
            exclusionMode:ExclusionMode.Ignore
            aboveWindows:menuItem.menuOpen||menuItem.wipeHideRunning
            color:"transparent"
            WlrLayershell.keyboardFocus:menuItem.menuOpen?WlrKeyboardFocus.Exclusive:WlrKeyboardFocus.None
            implicitWidth:modelData.width;implicitHeight:modelData.height
            Menu{id:menuItem;anchors.fill:parent;screenW:modelData.width;screenH:modelData.height}
            Connections{target:root;function onMenuFireToggle(){
                if(root.menuActiveMonitor!==modelData.name)return
                if(menuItem.menuOpen)menuItem.closeMenu();else menuItem.openMenu()
            }}
        }
    }


    // ── PLAYER ── mouse sağ kenara gidince açılır (VolumeBar gibi, tuş gerekmez)
    // Mouse kenardan çekilince kapanır. Fullscreen üstüne çıkmaz.
    Variants {
        model:Quickshell.screens
        PanelWindow {
            id: playerPanel
            required property var modelData;screen:modelData
            anchors.top:true;anchors.right:true
            margins.top:Math.round(modelData.height*Settings.playerPositionY);margins.right:0
            exclusionMode:ExclusionMode.Ignore;aboveWindows:true;color:"transparent"
            visible:!root.playerBlocked
            implicitWidth:Settings.playerWidth;implicitHeight:playerItem.implicitHeight
            Player{id:playerItem;anchors.fill:parent
                mpTitle:root.mpTitle;mpArtist:root.mpArtist;mpCoverUrl:root.mpCoverUrl
                mpPlaying:root.mpPlaying;mpPosition:root.mpPosition;mpLength:root.mpLength
                onPlayPause:pcPlay.running=true;onNextTrack:pcNext.running=true;onPrevTrack:pcPrev.running=true}
            Connections{target:root;function onPlayerVisibleChanged(){playerItem.toggleVisible()}}
            Connections{target:root;function onPlayerBlockedChanged(){ if (root.playerBlocked && playerItem.shown) playerItem.toggleVisible() }}

            // Kenar şerit: sadece AÇAR (kapatma aşağıda polling ile yapılır)
            MouseArea {
                id: edgeStrip
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 18
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: {
                    if (!playerItem.shown) playerItem.toggleVisible()
                }
            }
            // Kapatma polling ile: cursor 3 tur üst üste dışarıdaysa gizle (~1sn)
            // Sürükleme (busy) bitene kadar sayaç sıfırlanır, o yüzden elinde kapanmaz
            property int outsideCount: 0
            Timer {
                interval: 350; running: true; repeat: true
                onTriggered: {
                    if (!playerItem.shown || playerItem.busy) { playerPanel.outsideCount = 0; return }
                    if (root.playerHover[modelData.name] === true) playerPanel.outsideCount = 0
                    else playerPanel.outsideCount++
                    if (playerPanel.outsideCount >= 3) {
                        playerPanel.outsideCount = 0
                        playerItem.toggleVisible()
                    }
                }
            }
        }
    }

    // ── TIMER POPUP ── bardan fırlar (waybar TMR modülü açar)
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen:modelData
            anchors.top:true;anchors.right:true
            margins.top:36;margins.right:20
            exclusionMode:ExclusionMode.Ignore
            aboveWindows:tpop.shown
            color:"transparent"
            visible:tpop.shown && !root.playerBlocked
            implicitWidth:300;implicitHeight:tpop.implicitHeight
            TimerPopup{id:tpop;anchors.fill:parent}
            Connections{target:root;function onTimerFireToggle(){
                if(root.timerActiveMonitor!==modelData.name){ if(tpop.shown) tpop.hide(); return }
                tpop.toggle()
            }}
        }
    }

    // ── COMPANIONS ──
    Variants {
        model:Settings.companionsEnabled ? Quickshell.screens : []
        PanelWindow {
            required property var modelData;screen:modelData
            anchors.bottom:true;anchors.right:true;margins.right:Settings.companionsMarginRight
            exclusionMode:ExclusionMode.Ignore;color:"transparent"
            implicitWidth:Settings.companionsSpriteSize+58;implicitHeight:compItem.implicitHeight
            Companions{id:compItem;anchors.fill:parent}
        }
    }
}
