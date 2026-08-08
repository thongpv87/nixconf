import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: osdWindow

    color: "transparent"
    visible: true

    anchors {
        bottom: true
        left: true
        right: true
    }
    margins {
        bottom: 80
    }
    implicitHeight: 60

    mask: Region {}

    MatugenColors { id: theme }

    property int windowCount: 0
    property int activeIdx: 0
    property bool showOsd: false

    Timer {
        id: dismissTimer
        interval: 1200
        repeat: false
        onTriggered: {
            osdWindow.showOsd = false
        }
    }

    Process {
        id: osdDaemon
        command: ["bash", "-c", "~/.config/hypr/scripts/window_osd.sh"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                let txt = data.trim()
                if (txt !== "") {
                    try {
                        let parsed = JSON.parse(txt)
                        if (parsed.count !== undefined && parsed.activeIdx !== undefined) {
                            osdWindow.windowCount = parsed.count
                            osdWindow.activeIdx = parsed.activeIdx
                            
                            if (parsed.count > 2) {
                                osdWindow.showOsd = true
                                dismissTimer.restart()
                            } else {
                                osdWindow.showOsd = false
                            }
                        }
                    } catch(e) {}
                }
            }
        }
    }

    Rectangle {
        id: container
        anchors.centerIn: parent
        height: 34
        width: dotsRow.implicitWidth + 28
        radius: 17
        
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.88)
        border.width: 1
        border.color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.12)

        opacity: osdWindow.showOsd ? 1.0 : 0.0
        scale: osdWindow.showOsd ? 1.0 : 0.85

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        Row {
            id: dotsRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: osdWindow.windowCount

                Rectangle {
                    required property int index
                    
                    property bool isActive: index === osdWindow.activeIdx

                    width: isActive ? 22 : 8
                    height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter

                    color: isActive ? theme.mauve : Qt.rgba(theme.overlay0.r, theme.overlay0.g, theme.overlay0.b, 0.45)

                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
}
