import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg
    property bool syncingPayoutFromWallet: false
    property bool minerLogAutoFollow: true

    function quoteShell(value) {
        const text = String(value || "")
        if (text.length === 0) return "''"
        return "'" + text.replace(/'/g, "'\\''") + "'"
    }

    function currentPoolUrl() {
        return minerPool.text.length > 0 ? minerPool.text : "stratum+tcp://defcoin.dc903.org:13372"
    }

    function currentPayout() {
        return minerPayout.text.trim()
    }

    function currentPassword() {
        return minerPassword.text.trim().length > 0 ? minerPassword.text.trim() : "x"
    }

    function previewPassword() {
        const text = currentPassword()
        return text === "x" ? "x" : "[redacted]"
    }

    function currentThreads() {
        const value = parseInt(minerThreads.text)
        return isNaN(value) ? 4 : Math.max(1, Math.min(256, value))
    }

    function currentNice() {
        const value = parseInt(minerNice.text)
        return isNaN(value) ? 20 : Math.max(0, Math.min(20, value))
    }

    function configurationProblem() {
        if (NuService.minerExecutable.length === 0)
            return "Select a cpuminer-compatible executable first."
        if (currentPoolUrl().indexOf("stratum+tcp://") !== 0 && currentPoolUrl().indexOf("stratum+ssl://") !== 0)
            return "Pool URL should start with stratum+tcp:// or stratum+ssl://."
        if (currentPayout().length === 0)
            return "Enter a Defcoin payout address or use the active wallet receive address."
        return ""
    }

    function minerArgsText() {
        return "-a scrypt -o " + quoteShell(currentPoolUrl())
             + " -u " + quoteShell(currentPayout())
             + " -p " + quoteShell(previewPassword())
             + " -t " + currentThreads()
    }

    function resolvedMinerExecutableForPreview() {
        const exe = NuService.minerExecutable.length > 0 ? NuService.minerExecutable : "/path/to/cpuminer"
        if (exe.toLowerCase().endsWith(".sh")) {
            const slash = Math.max(exe.lastIndexOf("/"), exe.lastIndexOf("\\"))
            if (slash >= 0)
                return exe.substring(0, slash + 1) + "cpuminer"
        }
        return exe
    }

    function commandPreview() {
        const exe = resolvedMinerExecutableForPreview()
        if (Qt.platform.os === "osx" && currentNice() > 0) {
            return "taskpolicy -b nice -n " + currentNice() + " " + quoteShell(exe) + " " + minerArgsText()
        }
        if (Qt.platform.os !== "windows" && currentNice() > 0) {
            return "nice -n " + currentNice() + " " + quoteShell(exe) + " " + minerArgsText()
        }
        return quoteShell(exe) + " " + minerArgsText()
    }

    function configPreview() {
        return JSON.stringify({
            url: currentPoolUrl(),
            user: currentPayout(),
            pass: previewPassword(),
            algo: "scrypt",
            threads: currentThreads(),
            "cpu-affinity": -1,
            "stratum-keepalive": true,
            quiet: false
        }, null, 2)
    }

    function parseDecimal(value, fallbackValue) {
        const cleaned = String(value || "").replace(/,/g, "").replace(/DFC/gi, "").trim()
        const parsed = Number(cleaned)
        return Number.isFinite(parsed) ? parsed : fallbackValue
    }

    function currentBlockReward() {
        const height = Math.max(0, Number(NuService.blockHeight || 0))
        const halvings = Math.floor(height / 840000)
        return Math.max(0, 50 / Math.pow(2, halvings))
    }

    function calculatorDifficulty() {
        return parseDecimal(rewardDifficulty.text, 0)
    }

    function calculatorHashrate() {
        return parseDecimal(rewardHashrate.text, 0)
    }

    function calculatorBlockReward() {
        return parseDecimal(rewardBlockValue.text, 0)
    }

    function calculatorCoinsPerDay() {
        const difficulty = calculatorDifficulty()
        const hashrate = calculatorHashrate()
        const reward = calculatorBlockReward()
        if (difficulty <= 0 || hashrate <= 0 || reward <= 0) return 0
        const secondsPerBlock = (difficulty * 4294967296) / (hashrate * 1000)
        if (!Number.isFinite(secondsPerBlock) || secondsPerBlock <= 0) return 0
        return (86400 / secondsPerBlock) * reward
    }

    function currentMinerHashrateKh() {
        const raw = String(NuService.minerHashrateText || "").replace(/,/g, "").trim()
        if (raw.length === 0 || raw === "-") return 0

        const match = raw.match(/([0-9]+(?:\.[0-9]+)?)\s*([KMGT]?)(?:H\/s|hash\/s|hashes\/s)?/i)
        if (!match) return 0

        let value = Number(match[1])
        if (!Number.isFinite(value) || value <= 0) return 0

        const unit = String(match[2] || "").toUpperCase()
        if (unit === "M") value *= 1000
        else if (unit === "G") value *= 1000000
        else if (unit === "T") value *= 1000000000
        else if (unit.length === 0 && raw.match(/\bH\/s\b/i)) value /= 1000
        return value
    }

    function formatCalculatorValue(value) {
        if (!Number.isFinite(value) || value <= 0) return ""
        return value.toFixed(value >= 100 ? 2 : 4).replace(/0+$/, "").replace(/\.$/, "")
    }

    function useCurrentRewardDefaults() {
        rewardDifficulty.text = parseDecimal(NuService.networkDifficulty, 0.091).toFixed(8).replace(/0+$/, "").replace(/\.$/, "")
        rewardBlockValue.text = root.currentBlockReward().toFixed(8).replace(/0+$/, "").replace(/\.$/, "")
        const minerHashrate = root.currentMinerHashrateKh()
        if (minerHashrate > 0)
            rewardHashrate.text = root.formatCalculatorValue(minerHashrate)
    }

    function saveConfig() {
        NuService.saveMinerConfiguration(currentPoolUrl(), currentPayout(), currentPassword(), currentThreads(), currentNice())
    }

    NuPageHeader {
        Layout.fillWidth: true
        title: "Mining"
        detail: "Configure, launch, and monitor a local scrypt miner."
    }

    NuTabBar {
        id: miningTabs
        Layout.fillWidth: true
        NuTabButton { text: "Setup" }
        NuTabButton { text: "Pools" }
        NuTabButton { text: "Run" }
        NuTabButton { text: "Monitor" }
        NuTabButton { text: "Reward Calculator" }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: miningTabs.currentIndex

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    text: "Nu does not bundle miner binaries. Some operating-system store policies restrict cryptocurrency miners inside app packages, so choose a miner executable you trust and Nu will build the scrypt stratum command for it."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    text: "CPU mining is included mainly for pool-connectivity testing and small Defcoin payouts. Defcoin uses Scrypt, like Litecoin and Dogecoin; modern Scrypt mining is efficient only on ASIC hardware, so avoid long CPU mining sessions unless you accept the heat, fan wear, and power use."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    columns: 2
                    rowSpacing: NuTokens.spaceMd
                    columnSpacing: NuTokens.spaceLg

                    Label { text: "Miner type"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
                    NuComboBox {
                        id: minerType
                        Layout.fillWidth: true
                        model: ["cpuminer"]
                        helpText: "Nu currently launches cpuminer-compatible CPU miners."
                    }

                    Label { text: "Executable"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceMd
                        NuTextField {
                            Layout.fillWidth: true
                            text: NuService.minerExecutable
                            readOnly: true
                            placeholderText: "No miner selected"
                            helpText: "Select a local cpuminer-compatible executable. The executable is not copied into the wallet."
                        }
                        NuActionButton {
                            Layout.preferredWidth: 160
                            text: "Select miner..."
                            helpText: "Choose a local miner executable, such as cpuminer-opt."
                            onClicked: NuService.chooseMinerExecutable()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: NuTokens.spaceMd
                    NuActionButton {
                        Layout.preferredWidth: 180
                        text: "Miner downloads"
                        helpText: "Open Defcoin Core's helper-binaries release with Defcoin-tested cpuminer-opt downloads."
                        onClicked: NuService.openExternalUrl("https://github.com/defcoincore/Defcoin-Core-Nu/releases/tag/cpuminer-opt-v26.1-defcoin")
                    }
                    NuActionButton {
                        Layout.preferredWidth: 190
                        text: "Miner source notes"
                        helpText: "Open the cpuminer-opt project page before downloading an executable."
                        onClicked: NuService.openExternalUrl("https://github.com/JayDDee/cpuminer-opt")
                    }
                    Item { Layout.fillWidth: true }
                }

                Item { Layout.fillHeight: true }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg

                Label {
                    Layout.fillWidth: true
                    text: "Choose a known Defcoin pool or enter a custom stratum endpoint. The payout address is passed to the miner as the username."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                NuComboBox {
                    id: minerPreset
                    Layout.fillWidth: true
                    model: [
                        "DC903 P2Pool - stratum+tcp://defcoin.dc903.org:13372",
                        "defcoin.io P2Pool - stratum+tcp://135.148.43.189:13372",
                        "defcoin.host - stratum+tcp://135.148.43.188:13371",
                        "Custom"
                    ]
                    helpText: "Choose a known pool preset or enter a custom stratum URL below."
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) minerPool.text = "stratum+tcp://defcoin.dc903.org:13372"
                        else if (currentIndex === 1) minerPool.text = "stratum+tcp://135.148.43.189:13372"
                        else if (currentIndex === 2) minerPool.text = "stratum+tcp://135.148.43.188:13371"
                    }
                }

                NuTextField {
                    id: minerPool
                    Layout.fillWidth: true
                    text: NuService.minerPoolUrl.length > 0 ? NuService.minerPoolUrl : "stratum+tcp://defcoin.dc903.org:13372"
                    placeholderText: "stratum+tcp://host:port"
                    helpText: "Stratum endpoint passed to the miner with -o."
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    NuTextField {
                        id: minerPayout
                        Layout.fillWidth: true
                        text: NuService.minerPayoutAddress
                        placeholderText: "Defcoin payout address"
                        helpText: "Payout address passed to the miner with -u. Use a receiving address from the active wallet or another address you control."
                    }
                    NuActionButton {
                        Layout.preferredWidth: 170
                        text: "Use wallet address"
                        enabled: NuService.walletSelected
                        helpText: "Use a receive address from the active wallet. If none is staged, Nu uses the first receive address in the address book or creates a Mining payout address."
                        onClicked: {
                            root.syncingPayoutFromWallet = true
                            NuService.useWalletReceiveAddressForMining()
                            if (NuService.minerPayoutAddress.length > 0) {
                                minerPayout.text = NuService.minerPayoutAddress
                            }
                        }
                    }
                }

                NuTextField {
                    id: minerPassword
                    Layout.fillWidth: true
                    text: NuService.minerPassword.length > 0 ? NuService.minerPassword : "x"
                    placeholderText: "x"
                    helpText: "Stratum password passed with -p. Most Defcoin pools accept x."
                }

                NuActionButton {
                    Layout.preferredWidth: 150
                    text: "Save pool"
                    helpText: "Save the pool URL, payout address, and password."
                    onClicked: root.saveConfig()
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    Label { text: "CPU threads"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: minerThreads
                        Layout.preferredWidth: 90
                        text: String(NuService.minerThreads > 0 ? NuService.minerThreads : 4)
                        placeholderText: "4"
                        validator: IntValidator { bottom: 1; top: 256 }
                        helpText: "Thread count passed to cpuminer-compatible miners with -t."
                    }
                    Label { text: "Nice"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: minerNice
                        Layout.preferredWidth: 74
                        text: String(NuService.minerNiceLevel >= 0 ? NuService.minerNiceLevel : 20)
                        placeholderText: "20"
                        validator: IntValidator { bottom: 0; top: 20 }
                        helpText: "Lower CPU priority. On macOS the generated command follows taskpolicy -b nice -n 20; use 0 for normal priority."
                    }
                    Item { Layout.fillWidth: true }
                    NuActionButton {
                        Layout.preferredWidth: 112
                        text: "Save"
                        helpText: "Save the local mining configuration."
                        onClicked: root.saveConfig()
                    }
                    NuActionButton {
                        Layout.preferredWidth: 120
                        text: NuService.minerRunning ? "Stop" : "Start"
                        primary: !NuService.minerRunning
                        helpText: "Start or stop the selected miner process with scrypt stratum arguments."
                        onClicked: {
                            root.saveConfig()
                            if (NuService.minerRunning) NuService.stopMiner()
                            else NuService.startConfiguredMiner()
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Note: Activity Monitor and similar tools may show a few helper threads in addition to the mining worker count. The -t setting controls cpuminer's mining worker threads."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Label {
                    Layout.fillWidth: true
                    text: root.configurationProblem().length > 0
                          ? root.configurationProblem()
                          : NuService.minerStatus
                    color: root.configurationProblem().length > 0
                           ? NuTokens.stateWarning
                           : (NuService.minerRunning ? NuTokens.accentSky : NuTokens.textSecondary)
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                Label {
                    Layout.fillWidth: true
                    visible: NuService.minerExecutable.toLowerCase().endsWith(".sh")
                    text: "A wrapper script is selected. Nu will launch the adjacent cpuminer executable directly so the settings on this page control the generated command."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: "Command preview"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBody
                    font.weight: Font.DemiBold
                }
                TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 88
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextArea.WrapAnywhere
                    text: root.commandPreview()
                    color: NuTokens.textPrimary
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontSmall
                    background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }
                }

                Label {
                    text: "Config preview"
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBody
                    font.weight: Font.DemiBold
                }
                TextArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextArea.NoWrap
                    text: root.configPreview()
                    color: NuTokens.textPrimary
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontSmall
                    background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceMd

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceXl
                    NuMetricRow { label: "Mining State"; value: NuService.miningStateText }
                    NuMetricRow { label: "Method"; value: NuService.miningMethodText }
                    NuMetricRow { label: "Hashrate"; value: NuService.minerHashrateText }
                    NuMetricRow { label: "Accepted"; value: String(NuService.minerAcceptedShares) }
                    NuMetricRow { label: "Rejected"; value: String(NuService.minerRejectedShares) }
                    NuActionButton {
                        width: 105
                        text: "Copy log"
                        enabled: NuService.minerLog.length > 0
                        helpText: "Copy the visible miner log buffer to the clipboard."
                        onClicked: NuService.copyText(NuService.minerLog)
                    }
                    NuActionButton {
                        width: 105
                        text: "Clear log"
                        enabled: NuService.minerLog.length > 0
                        helpText: "Clear Nu's in-app miner log buffer. This does not stop the miner."
                        onClicked: {
                            root.minerLogAutoFollow = true
                            NuService.clearMinerLog()
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Recent miner output. Nu keeps up to about 2 MB in this view; copy the log before clearing it."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Basic.ScrollView {
                    id: minerLogScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    Basic.ScrollBar.vertical: Basic.ScrollBar {
                        id: minerLogVerticalBar
                        policy: Basic.ScrollBar.AlwaysOn
                        onPositionChanged: root.minerLogAutoFollow = position + size >= 0.985
                        onSizeChanged: root.minerLogAutoFollow = position + size >= 0.985
                    }
                    Basic.ScrollBar.horizontal: Basic.ScrollBar {
                        policy: Basic.ScrollBar.AlwaysOn
                    }

                    TextArea {
                        id: minerLogText
                        width: Math.max(implicitWidth, minerLogScroll.availableWidth)
                        height: Math.max(implicitHeight, minerLogScroll.availableHeight)
                        readOnly: true
                        selectByMouse: true
                        text: NuService.minerLog.length > 0 ? NuService.minerLog : "Miner output will appear here after the process starts."
                        color: NuTokens.textPrimary
                        font.family: NuTokens.monoFont
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: TextArea.NoWrap
                        background: Rectangle {
                            color: NuTokens.backgroundBase
                            border.color: NuTokens.lineSubtle
                            radius: NuTokens.radiusSmall
                        }
                        onTextChanged: {
                            if (!root.minerLogAutoFollow)
                                return
                            Qt.callLater(function() {
                                minerLogText.cursorPosition = minerLogText.length
                                minerLogVerticalBar.position = Math.max(0, 1 - minerLogVerticalBar.size)
                            })
                        }
                    }
                }
            }
        }

        NuPanel {
            ColumnLayout {
                anchors.fill: parent
                spacing: NuTokens.spaceLg

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceSm
                        Label {
                            Layout.fillWidth: true
                            text: "Reward Calculator"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Estimate daily Defcoin output from current difficulty, block reward, and a miner hashrate. This follows the DC903 calculator formula and is a probability estimate, not a guarantee."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontBody
                            wrapMode: Text.WordWrap
                        }
                    }

                    NuActionButton {
                        Layout.preferredWidth: 180
                        text: "Use current values"
                        helpText: "Load current backend difficulty, current block reward, and the running miner hashrate when Nu is managing a miner."
                        onClicked: root.useCurrentRewardDefaults()
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: NuTokens.spaceMd
                    columnSpacing: NuTokens.spaceLg

                    Label { text: "Network Difficulty"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
                    NuTextField {
                        id: rewardDifficulty
                        Layout.fillWidth: true
                        text: parseDecimal(NuService.networkDifficulty, 0.091).toFixed(8).replace(/0+$/, "").replace(/\.$/, "")
                        placeholderText: "0.091"
                        helpText: "Current network difficulty from the backend. It can change at retarget boundaries, so estimates drift as the network changes."
                    }

                    Label { text: "Hashrate (KH/s)"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
                    NuTextField {
                        id: rewardHashrate
                        Layout.fillWidth: true
                        placeholderText: "Enter your hashrate"
                        helpText: "Enter miner speed in kilohashes per second. For example, 12.5 means 12.5 KH/s."
                    }

                    Label { text: "Block Reward (DFC)"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontBody }
                    NuTextField {
                        id: rewardBlockValue
                        Layout.fillWidth: true
                        text: root.currentBlockReward().toFixed(8).replace(/0+$/, "").replace(/\.$/, "")
                        placeholderText: "12.5"
                        helpText: "Current subsidy computed from Defcoin's 840,000-block halving interval. Pool fees and stale shares are not included."
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    radius: NuTokens.radiusMedium
                    color: NuTokens.backgroundBase
                    border.color: NuTokens.lineSubtle
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: NuTokens.spaceMd
                        spacing: NuTokens.spaceXs
                        Label {
                            Layout.fillWidth: true
                            text: root.calculatorCoinsPerDay().toFixed(8) + " DFC/day"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontTitle
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: root.calculatorHashrate() > 0 && root.calculatorDifficulty() > 0
                                  ? "At " + root.calculatorHashrate() + " KH/s and difficulty " + root.calculatorDifficulty() + ", expected output is based on difficulty * 2^32 work per block."
                                  : "Enter positive values for difficulty, hashrate, and reward to calculate a daily estimate."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Caveats: mining is probabilistic. Pool luck, pool fees, rejected or stale shares, difficulty changes, and hashrate fluctuations can make actual payouts differ from this estimate."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Connections {
        target: NuService
        function onMinerChanged() {
            if (root.syncingPayoutFromWallet && NuService.minerPayoutAddress.length > 0) {
                minerPayout.text = NuService.minerPayoutAddress
                root.syncingPayoutFromWallet = false
            }
        }
    }
}
