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
    property bool minerLogRecentFirst: false
    property bool minerLogFollowTailBeforeRecentFirst: true
    property bool adjustingMinerLogTail: false
    property string minerLogFilterPattern: ""
    property string minerLogRemovePattern: ""
    property string minerLogFilterError: ""
    property var minerLogFilterPresetModel: minerLogFilterPresets()
    property var miningPoolPresets: [
        { name: "DC903 P2Pool", url: "stratum+tcp://defcoin.dc903.org:13372", color: "#51a7f9" },
        { name: "defcoin.io P2Pool", url: "stratum+tcp://135.148.43.189:13372", color: "#33c481" },
        { name: "defcoin.host", url: "stratum+tcp://135.148.43.188:13371", color: "#f7b84b" },
        { name: "pool.defcoin.fun", url: "stratum+tcp://pool.defcoin.fun:3333", color: "#e85d75" },
        { name: "pool.defcoin.io", url: "stratum+tcp://pool.defcoin.io:4044", color: "#a77cf2" }
    ]

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

    function poolPresetLabels() {
        const labels = []
        for (let i = 0; i < root.miningPoolPresets.length; ++i) {
            const pool = root.miningPoolPresets[i]
            labels.push(pool.name + " - " + pool.url)
        }
        labels.push("Custom")
        return labels
    }

    function benchmarkPools() {
        const rows = []
        const seen = {}
        for (let i = 0; i < root.miningPoolPresets.length; ++i) {
            const pool = root.miningPoolPresets[i]
            rows.push({ name: pool.name, url: pool.url, color: pool.color })
            seen[String(pool.url).toLowerCase()] = true
        }
        const customUrl = root.currentPoolUrl().trim()
        if (customUrl.length > 0 && !seen[customUrl.toLowerCase()]) {
            rows.push({ name: "Custom", url: customUrl, color: "#19b8c7" })
        }
        return rows
    }

    function benchmarkSecondsPerPool() {
        const value = parseInt(benchmarkSeconds.text)
        return isNaN(value) ? 300 : Math.max(15, Math.min(86400, value))
    }

    function benchmarkCycles() {
        const value = parseInt(benchmarkCycleCount.text)
        return isNaN(value) ? 3 : Math.max(1, Math.min(100, value))
    }

    function formatBenchmarkDuration(seconds) {
        seconds = Math.max(0, Math.round(seconds))
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        const secs = seconds % 60
        if (hours > 0)
            return hours + "h " + String(minutes).padStart(2, "0") + "m " + String(secs).padStart(2, "0") + "s"
        return minutes + "m " + String(secs).padStart(2, "0") + "s"
    }

    function benchmarkEstimatedRuntime() {
        const starts = benchmarkPools().length * benchmarkCycles()
        return formatBenchmarkDuration(starts * benchmarkSecondsPerPool() + starts * 12)
    }

    function benchmarkRowsGrouped() {
        const rows = []
        const raw = NuService.miningBenchmarkRuns || []
        for (let i = 0; i < raw.length; ++i)
            rows.push(raw[i])
        rows.sort(function(a, b) {
            const an = String(a.poolName || "")
            const bn = String(b.poolName || "")
            if (an !== bn) return an < bn ? -1 : 1
            return Number(a.cycle || 0) - Number(b.cycle || 0)
        })
        return rows
    }

    function benchmarkAverage(field) {
        const rows = NuService.miningBenchmarkRuns || []
        let total = 0
        let count = 0
        for (let i = 0; i < rows.length; ++i) {
            const value = Number(rows[i][field])
            if (Number.isFinite(value) && value >= 0) {
                total += value
                ++count
            }
        }
        return count > 0 ? total / count : 0
    }

    function benchmarkTotal(field) {
        const rows = NuService.miningBenchmarkRuns || []
        let total = 0
        for (let i = 0; i < rows.length; ++i) {
            const value = Number(rows[i][field])
            if (Number.isFinite(value)) total += value
        }
        return total
    }

    function formatBenchmarkNumber(value, decimals) {
        value = Number(value)
        if (!Number.isFinite(value) || value < 0) return "-"
        return value.toFixed(decimals)
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

    function followMinerLogTail() {
        Qt.callLater(function() {
            root.adjustingMinerLogTail = true
            minerLogText.cursorPosition = minerLogText.length
            Qt.callLater(function() { root.adjustingMinerLogTail = false })
        })
    }

    function followMinerLogHead() {
        Qt.callLater(function() {
            root.adjustingMinerLogTail = true
            minerLogText.cursorPosition = 0
            Qt.callLater(function() { root.adjustingMinerLogTail = false })
        })
    }

    function safeMinerLogRegex(pattern) {
        const clean = String(pattern || "")
        if (clean.length === 0) return null
        if (clean.length > 160) {
            root.minerLogFilterError = "Regex filters are limited to 160 characters."
            return false
        }
        try {
            return new RegExp(clean, "i")
        } catch (error) {
            root.minerLogFilterError = "Malformed regex: " + error.message
            return false
        }
    }

    function minerLogFilterPresets() {
        return [
            "[type search term here]",
            "Accepted",
            "Submitted Diff",
            "Rejected|reject|stale",
            "Hash rate|hashrate",
            "Share rate",
            "New Stratum Diff",
            "Count mismatch|pending",
            "Lost hash rate",
            "TTF|Block",
            "scrypt:|stratum",
            "error|failed|timeout|disconnect"
        ]
    }

    function minerLogPresetValue(label) {
        const text = String(label || "")
        return text === "[type search term here]" ? "" : text
    }

    function displayedMinerLog() {
        root.minerLogFilterError = ""
        const raw = String(NuService.minerLog || "")
        if (raw.length === 0)
            return "Miner output will appear here after the process starts."
        const include = safeMinerLogRegex(root.minerLogFilterPattern)
        const remove = safeMinerLogRegex(root.minerLogRemovePattern)
        let lines = raw.split(/\r?\n/)
        while (lines.length > 0 && lines[lines.length - 1].length === 0)
            lines.pop()
        if (include !== false && remove !== false) {
            lines = lines.filter(function(line) {
                const text = String(line || "")
                if (include && !include.test(text)) return false
                if (remove && remove.test(text)) return false
                return true
            })
        }
        lines.reverse()
        if (!root.minerLogRecentFirst)
            lines.reverse()
        if (lines.length === 0)
            return "No miner log lines match the current Filter and Remove settings."
        return lines.join("\n") + "\n"
    }

    function refreshMinerLogView() {
        if (root.minerLogRecentFirst)
            root.followMinerLogHead()
        else if (root.minerLogAutoFollow)
            root.followMinerLogTail()
    }

    function findInMinerLog(backward) {
        const needle = String(minerLogFindField.text || "")
        if (needle.length === 0) return
        const hay = minerLogText.text
        const lowerHay = hay.toLowerCase()
        const lowerNeedle = needle.toLowerCase()
        var index = -1
        if (backward) {
            const startBack = Math.max(0, minerLogText.selectionStart - 1)
            index = lowerHay.lastIndexOf(lowerNeedle, startBack)
            if (index < 0) index = lowerHay.lastIndexOf(lowerNeedle)
        } else {
            const startForward = Math.max(0, minerLogText.selectionEnd)
            index = lowerHay.indexOf(lowerNeedle, startForward)
            if (index < 0) index = lowerHay.indexOf(lowerNeedle)
        }
        if (index >= 0) {
            minerLogText.forceActiveFocus()
            minerLogText.select(index, index + needle.length)
            minerLogText.cursorPosition = index + needle.length
        }
    }

    function saveConfig() {
        NuService.saveMinerConfiguration(currentPoolUrl(), currentPayout(), currentPassword(), currentThreads(), currentNice())
    }

    function requestMiningTab(tabName) {
        const clean = String(tabName || "").toLowerCase()
        miningTabs.currentIndex = clean === "pools" ? 1
                                : clean === "benchmark" || clean === "benchmark-pools" ? 2
                                : clean === "run" ? 3
                                : clean === "monitor" ? 4
                                : clean === "reward" || clean === "reward-calculator" ? 5
                                : 0
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
        NuTabButton { text: "Benchmark Pools" }
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
                    model: root.poolPresetLabels()
                    helpText: "Choose a known pool preset or enter a custom stratum URL below."
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < root.miningPoolPresets.length)
                            minerPool.text = root.miningPoolPresets[currentIndex].url
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
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: NuTokens.spaceXs
                        Label {
                            Layout.fillWidth: true
                            text: "Benchmark Pools"
                            color: NuTokens.textPrimary
                            font.pixelSize: NuTokens.fontBodyLarge
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Runs each preset pool with the saved miner settings, adds the custom pool if it differs, pings before every run, and saves the latest chart and stats automatically."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    NuActionButton {
                        Layout.preferredWidth: 142
                        text: "Load old run"
                        helpText: "Load a previously autosaved benchmark JSON file and chart."
                        onClicked: NuService.loadMiningBenchmarkRun()
                    }
                    NuActionButton {
                        Layout.preferredWidth: 126
                        text: "Open folder"
                        helpText: "Open the benchmark autosave folder."
                        onClicked: NuService.openMiningBenchmarkFolder()
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    Label {
                        text: "Per pool"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    NuTextField {
                        id: benchmarkSeconds
                        width: 92
                        text: "300"
                        validator: IntValidator { bottom: 15; top: 86400 }
                        helpText: "Seconds to mine on each pool before switching. Default is 300 seconds."
                    }
                    Label {
                        text: "Cycles"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                    }
                    NuTextField {
                        id: benchmarkCycleCount
                        width: 72
                        text: "3"
                        validator: IntValidator { bottom: 1; top: 100 }
                        helpText: "How many times to loop over the pool list. Default is three cycles."
                    }
                    NuMetricRow {
                        label: "Pools"
                        value: String(root.benchmarkPools().length)
                        helpText: "Preset pools plus the custom field when it is different from every preset."
                    }
                    NuMetricRow {
                        label: "Est. runtime"
                        value: root.benchmarkEstimatedRuntime()
                        valueMaximumWidth: 140
                        helpText: "Pool time plus an estimated 10-ping check and restart overhead for every pool run."
                    }
                    NuMetricRow {
                        label: "Time left"
                        value: NuService.miningBenchmarkEta
                        valueMaximumWidth: 140
                        helpText: "Estimated benchmark time remaining, based on configured pool time and observed restart time."
                    }
                    NuActionButton {
                        width: 150
                        text: NuService.miningBenchmarkRunning ? "Stop benchmark" : "Start benchmark"
                        primary: !NuService.miningBenchmarkRunning
                        danger: NuService.miningBenchmarkRunning
                        helpText: "Start or stop the full pool benchmark sequence."
                        onClicked: {
                            if (NuService.miningBenchmarkRunning) {
                                NuService.stopMiningBenchmark()
                                return
                            }
                            root.saveConfig()
                            NuService.startMiningBenchmark(root.benchmarkPools(),
                                                           root.benchmarkSecondsPerPool(),
                                                           root.benchmarkCycles())
                        }
                    }
                    NuActionButton {
                        width: 120
                        enabled: (NuService.miningBenchmarkRuns || []).length > 0
                        text: "Export stats"
                        helpText: "Export the current benchmark JSON stats file."
                        onClicked: NuService.exportMiningBenchmarkStats()
                    }
                    NuActionButton {
                        width: 122
                        enabled: (NuService.miningBenchmarkRuns || []).length > 0
                        text: "Export chart"
                        helpText: "Export the current benchmark chart PNG."
                        onClicked: NuService.exportMiningBenchmarkChart()
                    }
                }

                ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: NuService.miningBenchmarkProgress
                    visible: NuService.miningBenchmarkRunning || NuService.miningBenchmarkProgress > 0
                }

                Label {
                    Layout.fillWidth: true
                    text: NuService.miningBenchmarkStatus
                    color: NuService.miningBenchmarkRunning ? NuTokens.accentSky : NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceLg
                    NuMetricRow {
                        label: "Total accepted"
                        value: String(Math.round(root.benchmarkTotal("accepted")))
                        helpText: "Raw accepted pool shares summed across all completed pool runs. Pools can use different share difficulty, so this is a diagnostic count rather than the fairness metric."
                    }
                    NuMetricRow {
                        label: "Avg work/s"
                        value: root.formatBenchmarkNumber(root.benchmarkAverage("acceptedDifficultyPerSecond"), 6)
                        helpText: "Average accepted share difficulty per second. This normalizes pools that assign different share difficulty."
                    }
                    NuMetricRow {
                        label: "Avg hashrate"
                        value: root.formatBenchmarkNumber(root.benchmarkAverage("hashrateKh"), 2) + " KH/s"
                        helpText: "Average parsed miner hashrate across completed runs."
                    }
                    NuMetricRow {
                        label: "Avg ping"
                        value: root.formatBenchmarkNumber(root.benchmarkAverage("pingAvgMs"), 1) + " ms"
                        helpText: "Average of the ten-ping check before each pool run."
                    }
                    NuMetricRow {
                        label: "Avg restart"
                        value: root.formatBenchmarkNumber(root.benchmarkAverage("restartMs"), 0) + " ms"
                        helpText: "Average measured stop/start switching time in the benchmark run log."
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 260
                    radius: NuTokens.radiusMedium
                    color: NuTokens.backgroundBase
                    border.color: NuTokens.lineSubtle
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: NuTokens.spaceSm
                        source: NuService.miningBenchmarkChartSource
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        visible: source.toString().length > 0
                    }

                    Label {
                        anchors.centerIn: parent
                        width: parent.width - NuTokens.spaceXl * 2
                        visible: NuService.miningBenchmarkChartSource.length === 0
                        text: "Last run's chart will appear here after the benchmark saves its first chart."
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }

                Basic.ScrollView {
                    id: benchmarkResultsScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    Basic.ScrollBar.vertical.policy: Basic.ScrollBar.AlwaysOn
                    Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOn

                    Column {
                        width: Math.max(benchmarkResultsHeader.implicitWidth, benchmarkResultsScroll.availableWidth)
                        spacing: 0

                        Row {
                            id: benchmarkResultsHeader
                            spacing: 0
                            Repeater {
                                model: ["Pool", "Cycle", "Duration", "Accepted", "Work/s", "Hashrate", "Ping", "Restart", "Status"]
                                delegate: Rectangle {
                                    width: [190, 64, 88, 92, 104, 116, 86, 92, 120][index]
                                    height: 34
                                    color: NuTokens.panelBase
                                    border.color: NuTokens.lineSubtle
                                    Label {
                                        anchors.fill: parent
                                        anchors.margins: NuTokens.spaceXs
                                        text: modelData
                                        color: NuTokens.textPrimary
                                        font.pixelSize: NuTokens.fontSmall
                                        font.weight: Font.DemiBold
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: root.benchmarkRowsGrouped()
                            delegate: Row {
                                spacing: 0
                                property var rowData: modelData
                                property var values: [
                                    rowData.poolName || "-",
                                    String(rowData.cycle || "-"),
                                    root.formatBenchmarkDuration(rowData.durationSeconds || 0),
                                    String(rowData.accepted || 0),
                                    root.formatBenchmarkNumber(rowData.acceptedDifficultyPerSecond, 6),
                                    rowData.hashrateText || "-",
                                    root.formatBenchmarkNumber(rowData.pingAvgMs, 1) + " ms",
                                    root.formatBenchmarkNumber(rowData.restartMs, 0) + " ms",
                                    rowData.status || "-"
                                ]
                                Repeater {
                                    model: parent.values
                                    delegate: Rectangle {
                                        width: [190, 64, 88, 92, 104, 116, 86, 92, 120][index]
                                        height: 30
                                        color: index === 0 ? Qt.rgba(0, 0, 0, 0.02) : "transparent"
                                        border.color: NuTokens.lineSubtle
                                        Rectangle {
                                            width: 4
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            color: index === 0 ? (rowData.color || NuTokens.accentSky) : "transparent"
                                        }
                                        Label {
                                            anchors.fill: parent
                                            anchors.leftMargin: index === 0 ? NuTokens.spaceMd : NuTokens.spaceXs
                                            anchors.rightMargin: NuTokens.spaceXs
                                            text: modelData
                                            color: NuTokens.textPrimary
                                            font.pixelSize: NuTokens.fontSmall
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: index >= 1 && index <= 7 ? Text.AlignRight : Text.AlignLeft
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            width: parent.width
                            height: (NuService.miningBenchmarkRuns || []).length === 0 ? 42 : 0
                            visible: (NuService.miningBenchmarkRuns || []).length === 0
                            text: "No completed benchmark rows yet."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
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
                    text: "Note: Activity Monitor and similar tools may show a few helper threads in addition to the mining worker count. The -t setting controls cpuminer's mining worker threads. On macOS, Nice 20 runs the miner in the background priority band and can slow or stall mining while Nu is behind other apps; use 0 for normal priority if mining should keep running at full speed."
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
                    NuMetricRow { label: "Method"; value: NuService.miningMethodText }
                    NuMetricRow { label: "Hashrate"; value: NuService.minerHashrateText }
                    NuMetricRow { label: "Accepted"; value: String(NuService.minerAcceptedShares) }
                    NuMetricRow { label: "Accepted/s"; value: NuService.minerAcceptedRateText }
                    NuMetricRow { label: "Rejected"; value: String(NuService.minerRejectedShares) }
                    NuCheckBox {
                        text: "Follow tail"
                        checked: !root.minerLogRecentFirst && root.minerLogAutoFollow
                        enabled: !root.minerLogRecentFirst
                        helpText: "Keep the newest miner output visible at the bottom of the monitor."
                        onToggled: {
                            root.minerLogAutoFollow = checked
                            if (checked)
                                root.followMinerLogTail()
                        }
                    }
                    NuCheckBox {
                        text: "Recent Logs to Top"
                        checked: root.minerLogRecentFirst
                        helpText: "Show new miner output at the top of the monitor instead of following the bottom tail."
                        onToggled: {
                            if (checked) {
                                root.minerLogFollowTailBeforeRecentFirst = root.minerLogAutoFollow
                                root.minerLogRecentFirst = true
                                root.followMinerLogHead()
                            } else {
                                root.minerLogRecentFirst = false
                                root.minerLogAutoFollow = root.minerLogFollowTailBeforeRecentFirst
                                if (root.minerLogAutoFollow)
                                    root.followMinerLogTail()
                            }
                            root.refreshMinerLogView()
                        }
                    }
                    NuActionButton {
                        width: 105
                        text: "Copy log"
                        enabled: NuService.minerLog.length > 0
                        helpText: "Copy the visible miner log buffer to the clipboard."
                        onClicked: NuService.copyText(root.displayedMinerLog())
                    }
                    NuActionButton {
                        width: 105
                        text: "Clear log"
                        enabled: NuService.minerLog.length > 0
                        helpText: "Clear Nu's in-app miner log buffer. This does not stop the miner."
                        onClicked: {
                            root.minerLogAutoFollow = true
                            root.minerLogFollowTailBeforeRecentFirst = true
                            NuService.clearMinerLog()
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm
                    Label { text: "Filter:"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuComboBox {
                        id: minerLogSearchFilter
                        width: 250
                        editable: true
                        model: root.minerLogFilterPresetModel
                        currentIndex: 0
                        helpText: "Show only matching miner log lines. Choose a useful regex preset or type your own."
                        onAccepted: {
                            root.minerLogFilterPattern = editText.substring(0, 160)
                            root.refreshMinerLogView()
                        }
                        onActivated: function(index) {
                            const value = root.minerLogPresetValue(root.minerLogFilterPresetModel[index])
                            editText = value
                            root.minerLogFilterPattern = value
                            root.refreshMinerLogView()
                        }
                        onActiveFocusChanged: if (!activeFocus) {
                            root.minerLogFilterPattern = editText.substring(0, 160)
                            root.refreshMinerLogView()
                        }
                    }
                    Label { text: "Remove:"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        width: 170
                        text: root.minerLogRemovePattern
                        maximumLength: 160
                        placeholderText: "hide regex"
                        helpText: "Hide matching miner log lines after Filter is applied."
                        onEditingFinished: {
                            root.minerLogRemovePattern = text
                            root.refreshMinerLogView()
                        }
                    }
                    Label { text: "Find:"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: minerLogFindField
                        width: 190
                        maximumLength: 120
                        placeholderText: "Find in shown log"
                        onAccepted: root.findInMinerLog(false)
                    }
                    NuActionButton { text: "Prev"; width: 72; onClicked: root.findInMinerLog(true) }
                    NuActionButton { text: "Next"; width: 72; onClicked: root.findInMinerLog(false) }
                    Label {
                        text: root.minerLogFilterError
                        color: NuTokens.stateWarning
                        font.pixelSize: NuTokens.fontSmall
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Recent miner output. Nu buffers only the newest 4K log lines so mining stays responsive; copy the log before clearing it."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Basic.ScrollView {
                    id: minerLogScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    Basic.ScrollBar.vertical.policy: Basic.ScrollBar.AlwaysOn
                    Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOn

                    TextArea {
                        id: minerLogText
                        width: Math.max(implicitWidth, minerLogScroll.availableWidth)
                        height: Math.max(implicitHeight, minerLogScroll.availableHeight)
                        readOnly: true
                        selectByMouse: true
                        text: root.displayedMinerLog()
                        color: NuTokens.textPrimary
                        font.family: NuTokens.monoFont
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: TextArea.NoWrap
                        persistentSelection: true
                        background: Rectangle {
                            color: NuTokens.backgroundBase
                            border.color: NuTokens.lineSubtle
                            radius: NuTokens.radiusSmall
                        }
                        onTextChanged: {
                            if (root.minerLogRecentFirst) {
                                root.followMinerLogHead()
                                return
                            }
                            if (!root.minerLogAutoFollow)
                                return
                            root.followMinerLogTail()
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
