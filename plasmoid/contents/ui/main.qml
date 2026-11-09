import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.workspace.components as WorkspaceComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string projectUrl: "https://github.com/mizhar-developer/battery-mode"
    readonly property string modeFile: "/var/lib/battery-mode/mode"
    readonly property string statusFile: "/var/lib/battery-mode/status.json"

    property string mode: "off"
    property var status: ({})
    property bool daemonAlive: false
    property string pendingMode: ""
    property double pendingSince: 0

    // Combined figure for all batteries, taken from UPower's display device so it
    // matches the percentage on KDE's own battery icon.
    property int totalPercent: -1
    property string totalState: ""
    property string totalTimeText: ""
    readonly property string totalLine: totalPercent < 0 ? ""
        : "Total: " + totalPercent + "%" + (totalTimeText !== "" ? "   " + totalTimeText : "")

    readonly property var modeLabels: ({ "off": "Off", "full": "Full charge", "default": "Default 5-80%", "plan": "My plan" })
    readonly property string modeLabel: modeLabels[mode] || mode
    readonly property string statusMessage: daemonAlive
        ? (status.message || "")
        : "The battery-mode background service is not running."
    readonly property string batteryLine: {
        const b = status.batteries;
        if (!b || !b.BAT0 || !b.BAT1) return "";
        const c0 = b.BAT0.capacity === null || b.BAT0.capacity === undefined ? "?" : b.BAT0.capacity + "%";
        const c1 = !b.BAT1.present ? "not present" : (b.BAT1.capacity === null || b.BAT1.capacity === undefined ? "?" : b.BAT1.capacity + "%");
        return "Battery 1: " + c0 + "   Battery 2: " + c1 + "   " + (status.ac ? "Charger connected" : "On battery");
    }

    // Own glyph (battery with a toggle inside), shipped inside the package so it
    // needs no icon theme; the current mode shows as a letter badge on top of it.
    Plasmoid.icon: Qt.resolvedUrl("../icons/batterymode-symbolic.svg")
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    toolTipMainText: "Battery mode: " + modeLabel
    toolTipSubText: (totalLine !== "" ? totalLine + "\n" : "") + statusMessage

    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 10

    function setMode(m) {
        pendingMode = m;
        pendingSince = Date.now();
        mode = m;
        cmdSource.connectSource("printf '%s' '" + m + "' > " + modeFile);
    }

    P5Support.DataSource {
        id: cmdSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
    }

    P5Support.DataSource {
        id: statusSource
        engine: "executable"
        connectedSources: ["cat " + root.statusFile + " 2>/dev/null"]
        interval: 3000
        onNewData: (sourceName, data) => {
            const out = data["stdout"] || "";
            let s = null;
            try { s = JSON.parse(out); } catch (e) { s = null; }
            if (!s) {
                root.daemonAlive = false;
                return;
            }
            root.status = s;
            root.daemonAlive = (Date.now() / 1000 - (s.updated || 0)) < 90;
            const fileMode = s.mode || "off";
            if (root.pendingMode !== "") {
                if (fileMode === root.pendingMode || Date.now() - root.pendingSince > 20000) {
                    root.pendingMode = "";
                    root.mode = fileMode;
                }
            } else {
                root.mode = fileMode;
            }
        }
    }

    P5Support.DataSource {
        id: upowerSource
        engine: "executable"
        connectedSources: ["upower -i /org/freedesktop/UPower/devices/DisplayDevice 2>/dev/null"]
        interval: 5000
        onNewData: (sourceName, data) => {
            const out = data["stdout"] || "";
            const pct = out.match(/percentage:\s*([\d.]+)\s*%/);
            const state = out.match(/state:\s*(\S+)/);
            const toEmpty = out.match(/time to empty:\s*([\d.]+)\s*(\w+)/);
            const toFull = out.match(/time to full:\s*([\d.]+)\s*(\w+)/);
            root.totalPercent = pct ? Math.round(parseFloat(pct[1])) : -1;
            root.totalState = state ? state[1] : "";
            const t = toFull || toEmpty;
            if (!t) {
                root.totalTimeText = "";
                return;
            }
            let minutes = parseFloat(t[1]);
            if (t[2].startsWith("hour")) minutes *= 60;
            else if (t[2].startsWith("second")) minutes /= 60;
            minutes = Math.round(minutes);
            const h = Math.floor(minutes / 60), m = minutes % 60;
            const span = h > 0 ? h + " h " + m + " min" : m + " min";
            root.totalTimeText = toFull ? span + " until full" : span + " remaining";
        }
    }

    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        activeFocusOnTab: true
        Accessible.name: root.toolTipMainText
        Accessible.role: Accessible.Button
        // Same pattern as KDE's own tray applets: remember the state at press time so a
        // click on the icon while the popup is open closes it instead of re-opening it.
        property bool wasExpanded: false
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        Kirigami.Icon {
            id: compactIcon
            anchors.fill: parent
            source: Plasmoid.icon
            isMask: true   // tint the bundled SVG with the panel text colour
            active: compact.containsMouse
        }
        WorkspaceComponents.BadgeOverlay {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.mode !== "off"
            text: root.mode === "full" ? "F" : root.mode === "default" ? "D" : "P"
            icon: compactIcon
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        collapseMarginsHint: true

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                level: 3
                text: "Battery charging mode"
            }

            PC3.Switch {
                id: fullSwitch
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                text: "Full charge"
                checked: root.mode === "full"
                onToggled: {
                    root.setMode(checked ? "full" : "off");
                    checked = Qt.binding(() => root.mode === "full");
                }
            }
            PC3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2.5
                text: "Both batteries charge all the way to 100%."
                opacity: 0.7
                font: Kirigami.Theme.smallFont
                wrapMode: Text.Wrap
            }

            PC3.Switch {
                id: defaultSwitch
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                text: "Default 5-80%"
                checked: root.mode === "default"
                onToggled: {
                    root.setMode(checked ? "default" : "off");
                    checked = Qt.binding(() => root.mode === "default");
                }
            }
            PC3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2.5
                text: "Each battery on its own: starts charging below 5%, stops at 80%."
                opacity: 0.7
                font: Kirigami.Theme.smallFont
                wrapMode: Text.Wrap
            }

            PC3.Switch {
                id: planSwitch
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                text: "My plan"
                checked: root.mode === "plan"
                onToggled: {
                    root.setMode(checked ? "plan" : "off");
                    checked = Qt.binding(() => root.mode === "plan");
                }
            }
            PC3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2.5
                text: "Nothing charges until Battery 1 is at 5%. Then Battery 1 to 80%, then Battery 2 to 80%, then stop."
                opacity: 0.7
                font: Kirigami.Theme.smallFont
                wrapMode: Text.Wrap
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            PC3.Label {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                text: root.statusMessage
                wrapMode: Text.Wrap
            }
            PC3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                visible: !root.daemonAlive
                text: "Install or start it with the install script from <a href=\"" + root.projectUrl + "\">the project page</a>."
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                font: Kirigami.Theme.smallFont
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
            PC3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                visible: root.totalLine !== ""
                text: root.totalLine
                font.bold: true
                wrapMode: Text.Wrap
            }
            PC3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                visible: root.batteryLine !== ""
                text: root.batteryLine
                opacity: 0.7
                font: Kirigami.Theme.smallFont
                wrapMode: Text.Wrap
            }
        }
    }
}
