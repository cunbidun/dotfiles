import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ModuleChip {
    id: root

    required property var panelWindow

    property bool popupOpen: false
    property var connections: []
    property string fetchError: ""
    property bool loading: false
    property var lastUpdated: null

    // Lowest remaining percentage across every metered quota, or -1 when there
    // is nothing to meter. Balances (unlimited) are excluded — they never run
    // out on a timer, so they should not drive the chip color.
    readonly property real worstPercent: {
        let worst = -1;
        for (const connection of root.connections) {
            for (const quota of connection.quotas) {
                if (quota.unlimited) {
                    continue;
                }

                if (worst < 0 || quota.percent < worst) {
                    worst = quota.percent;
                }
            }
        }
        return worst;
    }

    readonly property string iconRoot: `${Quickshell.env("HOME")}/dotfiles/nix/quickshell/assets/icons`

    // The brand mark carries its own color, so status is signalled by a corner
    // dot that only appears when something actually needs attention.
    readonly property bool statusAlert: root.fetchError.length > 0
        || (root.worstPercent >= 0 && root.worstPercent <= root.theme.aiQuotaWarnPercent)
    readonly property color statusColor: {
        if (root.fetchError.length > 0 || root.worstPercent < 0) {
            return root.theme.iconMutedColor;
        }

        return root.worstPercent <= root.theme.aiQuotaDangerPercent
            ? root.theme.popupDanger
            : root.theme.popupWarning;
    }

    iconSource: `file://${root.iconRoot}/9router.svg`
    activate: () => {
        root.popupOpen = true;
        root.refresh();
    }

    Rectangle {
        id: statusDot

        visible: root.statusAlert
        width: Math.round(root.theme.em * 0.58)
        height: width
        radius: width / 2
        color: root.statusColor
        // The warning color is orange in several themes — near-identical to the
        // 9Router tile — so the dot needs a ring to read as a separate badge.
        border.width: 1
        border.color: root.theme.chipText
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Math.round(root.theme.em * 0.12)
        anchors.topMargin: Math.round(root.theme.em * 0.12)
    }

    // Fans the per-connection usage requests out in parallel, then emits a
    // single normalized array. Provider payloads differ (codex reports one
    // `session` bucket, github three, deepseek a dollar balance), so the jq
    // pass flattens them all to {name, used, total, remaining, percent}.
    Process {
        id: quotaQuery

        command: ["bash", "-lc", `
set -o pipefail
base="$1"
providers=$(curl -fsS -m 8 "$base/api/providers") || exit 1
rows=$(printf '%s' "$providers" | jq -r '.connections[]? | [.id, (.provider // "?"), (.name // "?")] | @tsv')
[ -n "$rows" ] || { echo '[]'; exit 0; }

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

while IFS=$'\\t' read -r id provider account; do
  [ -n "$id" ] || continue
  (
    trap - EXIT
    usage=$(curl -fsS -m 8 "$base/api/usage/$id" 2>/dev/null) || usage='{}'
    printf '%s' "$usage" | jq -c --arg id "$id" --arg provider "$provider" --arg account "$account" '
      def num($v): if ($v | type) == "number" then $v else 0 end;
      {
        id: $id,
        provider: $provider,
        account: $account,
        plan: (.plan // null),
        quotas: [
          (.quotas // {}) | to_entries[] | {
            name:      (.value.name // .key),
            used:      num(.value.used),
            total:     num(.value.total),
            remaining: (if (.value.remaining | type) == "number"
                        then .value.remaining
                        else num(.value.total) - num(.value.used) end),
            unlimited: (.value.unlimited // false),
            resetAt:   (.value.resetAt // null)
          }
          | select(.unlimited or .total > 0)
          | . + { percent: (if .unlimited then 100
                            elif .total > 0 then (.remaining / .total * 100)
                            else 0 end) }
        ]
      }
      | select(.quotas | length > 0)
    ' >"$tmp/$id.json" 2>/dev/null || true
  ) &
done <<<"$rows"
wait

cat "$tmp"/*.json 2>/dev/null | jq -s -c 'sort_by(.provider, .account)'
`, "quickshell-ai-quota", root.theme.aiProxyUrl]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateQuota(text)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const message = text.trim();
                if (message.length > 0) {
                    console.warn(`[ai-quota] ${message}`);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode !== 0) {
                root.fetchError = `proxy unreachable (exit ${exitCode})`;
            }
        }
    }

    Timer {
        interval: root.theme.aiQuotaRefreshInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    PanelWindow {
        id: quotaPopup

        visible: root.popupOpen
        screen: root.panelWindow.screen
        color: root.theme.transparentColor

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: root.popupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-ai-quota-popup"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: root.popupOpen = false
        }

        FocusScope {
            anchors.fill: parent
            focus: root.popupOpen
            Keys.onEscapePressed: root.popupOpen = false
        }

        Item {
            id: popupFrame

            width: popupContent.width
            height: popupContent.height
            x: root.popupX(width, quotaPopup.width)
            y: root.theme.barOuterSpacing + root.theme.barHeight + root.theme.gap

            MouseArea { anchors.fill: parent }

            AiQuotaPopup {
                id: popupContent

                theme: root.theme
                connections: root.connections
                fetchError: root.fetchError
                loading: root.loading
                lastUpdated: root.lastUpdated
                refresh: () => root.refresh()
            }
        }
    }

    function refresh() {
        if (quotaQuery.running) {
            return;
        }

        root.loading = true;
        quotaQuery.running = true;
    }

    function updateQuota(rawText) {
        const trimmed = (rawText || "").trim();
        if (trimmed.length === 0) {
            return;
        }

        try {
            const parsed = JSON.parse(trimmed);
            root.connections = Array.isArray(parsed) ? parsed : [];
            root.fetchError = "";
            root.lastUpdated = new Date();
        } catch (error) {
            root.fetchError = `bad response (${error})`;
        }
    }
}
