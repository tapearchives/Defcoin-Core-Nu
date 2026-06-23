import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Defcoin.Nu 1.0

import "../Theme"
import "../Components"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceLg
    property bool syncingPayoutFromWallet: false
    property bool minerLogAutoFollow: true
    property bool minerLogRecentFirst: false
    property bool adjustingMinerLogTail: false
    property string minerLogDisplayText: "Miner output will appear here after the process starts."
    property string minerLogFilterPattern: ""
    property string minerLogRemovePattern: ""
    property string minerLogFilterError: ""
    property var minerLogFilterPresetModel: minerLogFilterPresets()
    property var miningPoolPresets: []
    property int poolEditorIndex: -1
    property string selectedPoolKey: ""
    property string poolEditorStatus: ""

    Component.onCompleted: {
        root.refreshMiningPoolPresetsFromService()
        root.updateMinerLogDisplayText()
    }

    Connections {
        target: NuService
        function onMinerChanged() {
            root.updateMinerLogDisplayText()
        }
    }

    function quoteShell(value) {
        const text = String(value || "")
        if (text.length === 0) return "''"
        return "'" + text.replace(/'/g, "'\\''") + "'"
    }

    function currentPoolUrl() {
        return minerPool.text.length > 0 ? minerPool.text : "stratum+tcp://135.148.43.188:13371"
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

    function defaultPoolColor(index) {
        const colors = ["#51a7f9", "#33c481", "#f7b84b", "#e85d75", "#a77cf2", "#19b8c7", "#d98534", "#6fcf97"]
        return colors[Math.max(0, index) % colors.length]
    }

    function shortPoolSoftware(value) {
        const text = String(value || "").trim()
        return text.toLowerCase() === "unknown stratum" || text.length === 0 ? "Unk. stratum" : text
    }

    function normalizedPoolSoftwareForPool(name, url, software) {
        const lowerName = String(name || "").toLowerCase()
        const lowerUrl = String(url || "").toLowerCase()
        if (lowerName.indexOf("pool.defcoin.fun") >= 0 || lowerUrl.indexOf("pool.defcoin.fun") >= 0)
            return "UNOMP"
        return root.shortPoolSoftware(software)
    }

    function validStratumUrl(url) {
        return /^stratum\+(tcp|ssl):\/\/(\[[0-9A-Fa-f:.]+\]|[A-Za-z0-9.-]+)(:[0-9]{1,5})?$/.test(String(url || "").trim())
    }

    function normalizePoolList(list) {
        const rows = []
        const seen = {}
        const source = list || []
        for (let i = 0; i < source.length; ++i) {
            const item = source[i] || {}
            const url = String(item.url || "").trim()
            if (!validStratumUrl(url))
                continue
            const key = url.toLowerCase()
            if (seen[key])
                continue
            seen[key] = true
            const name = String(item.name || "").trim()
            rows.push({
                name: name.length > 0 ? name : url.replace(/^stratum\+(tcp|ssl):\/\//, ""),
                url: url,
                poolSoftware: root.normalizedPoolSoftwareForPool(name, url, String(item.poolSoftware || "Unk. stratum").trim()),
                color: String(item.color || root.defaultPoolColor(rows.length)).trim(),
                payoutAddress: String(item.payoutAddress || "").trim(),
                password: String(item.password || "").trim()
            })
        }
        return rows
    }

    function refreshMiningPoolPresetsFromService() {
        root.miningPoolPresets = root.normalizePoolList(NuService.miningPoolPresets)
        if (root.miningPoolPresets.length > 0 && root.poolEditorIndex < 0)
            root.loadPoolByIndex(0)
    }

    function poolRowKey(pool, index) {
        return String(index) + ":" + String(pool.url || "").toLowerCase()
    }

    function poolTableRows() {
        const rows = []
        for (let i = 0; i < root.miningPoolPresets.length; ++i) {
            const pool = root.miningPoolPresets[i]
            rows.push({
                cells: [String(i + 1), String(pool.name || ""), String(pool.url || ""), String(pool.poolSoftware || ""),
                        String(pool.payoutAddress || "").length > 0 ? String(pool.payoutAddress || "") : "Inherit",
                        String(pool.password || "").length > 0 ? String(pool.password || "") : "Inherit"],
                meta: {
                    key: root.poolRowKey(pool, i),
                    index: i,
                    name: String(pool.name || ""),
                    url: String(pool.url || ""),
                    poolSoftware: String(pool.poolSoftware || ""),
                    payoutAddress: String(pool.payoutAddress || ""),
                    password: String(pool.password || ""),
                    noSort: i + 1,
                    nameSort: String(pool.name || ""),
                    urlSort: String(pool.url || ""),
                    softwareSort: String(pool.poolSoftware || ""),
                    payoutSort: String(pool.payoutAddress || "").length > 0 ? String(pool.payoutAddress || "") : "Inherit",
                    passwordSort: String(pool.password || "").length > 0 ? String(pool.password || "") : "Inherit",
                    cellTooltips: [
                        "Pool order. Hover over the number for an open-hand cursor, then click and hold until the closed hand appears and drag up or down to reorder presets.",
                        "Display name used in the Mining and Benchmark Pools views.",
                        "Stratum address passed to the miner with -o.",
                        "Known pool backend software, used for benchmark grouping.",
                        "Optional per-pool payout address. Inherited means Nu uses the general mining payout address.",
                        "Optional per-pool stratum password. Inherited means Nu uses the general mining password."
                    ]
                }
            })
        }
        return rows
    }

    function poolIndexForKey(key) {
        const clean = String(key || "")
        for (let i = 0; i < root.miningPoolPresets.length; ++i) {
            if (root.poolRowKey(root.miningPoolPresets[i], i) === clean)
                return i
        }
        return -1
    }

    function loadPoolByIndex(index) {
        if (index < 0 || index >= root.miningPoolPresets.length)
            return
        const pool = root.miningPoolPresets[index]
        root.poolEditorIndex = index
        root.selectedPoolKey = root.poolRowKey(pool, index)
        if (poolTable && poolTable.selectedRowKeys[0] !== root.selectedPoolKey)
            poolTable.setSelectedKeys([root.selectedPoolKey])
        poolNameField.text = String(pool.name || "")
        poolStratumField.text = String(pool.url || "")
        poolSoftwareField.text = String(pool.poolSoftware || "")
        poolPayoutField.text = String(pool.payoutAddress || "")
        poolPasswordField.text = String(pool.password || "")
        root.poolEditorStatus = ""
    }

    function loadPoolRow(row) {
        const index = Number((row.meta || {}).index)
        if (Number.isFinite(index))
            root.loadPoolByIndex(index)
    }

    function persistMiningPoolPresets() {
        root.miningPoolPresets = root.normalizePoolList(root.miningPoolPresets)
        NuService.saveMiningPoolPresets(root.miningPoolPresets)
    }

    function poolFromEditor() {
        return {
            name: poolNameField.text.trim(),
            url: poolStratumField.text.trim(),
            poolSoftware: root.shortPoolSoftware(poolSoftwareField.text.trim().length > 0 ? poolSoftwareField.text.trim() : "Unk. stratum"),
            payoutAddress: poolPayoutField.text.trim(),
            password: poolPasswordField.text.trim(),
            color: root.poolEditorIndex >= 0 && root.poolEditorIndex < root.miningPoolPresets.length
                   ? root.miningPoolPresets[root.poolEditorIndex].color
                   : root.defaultPoolColor(root.miningPoolPresets.length)
        }
    }

    function reorderPoolPreset(fromIndex, toIndex) {
        fromIndex = Math.max(0, Math.min(root.miningPoolPresets.length - 1, Number(fromIndex)))
        toIndex = Math.max(0, Math.min(root.miningPoolPresets.length - 1, Number(toIndex)))
        if (!Number.isFinite(fromIndex) || !Number.isFinite(toIndex) || fromIndex === toIndex)
            return
        const rows = root.miningPoolPresets.slice()
        const moved = rows.splice(fromIndex, 1)[0]
        rows.splice(toIndex, 0, moved)
        root.miningPoolPresets = rows
        root.poolEditorIndex = toIndex
        root.selectedPoolKey = root.poolRowKey(moved, toIndex)
        root.persistMiningPoolPresets()
        root.loadPoolByIndex(toIndex)
        root.poolEditorStatus = "Pool order updated."
    }

    function addPoolFromEditor() {
        const pool = root.poolFromEditor()
        if (pool.name.length === 0 || !root.validStratumUrl(pool.url)) {
            root.poolEditorStatus = "Enter a pool name and a stratum+tcp:// or stratum+ssl:// address."
            return
        }
        const key = pool.url.toLowerCase()
        for (let i = 0; i < root.miningPoolPresets.length; ++i) {
            if (String(root.miningPoolPresets[i].url || "").toLowerCase() === key) {
                root.poolEditorStatus = "That stratum address is already in the pool list."
                root.loadPoolByIndex(i)
                return
            }
        }
        const rows = root.miningPoolPresets.slice()
        rows.push(pool)
        root.miningPoolPresets = rows
        root.poolEditorIndex = rows.length - 1
        root.selectedPoolKey = root.poolRowKey(pool, root.poolEditorIndex)
        root.persistMiningPoolPresets()
        root.poolEditorStatus = "Pool added."
    }

    function updateSelectedPool() {
        const pool = root.poolFromEditor()
        if (root.poolEditorIndex < 0 || root.poolEditorIndex >= root.miningPoolPresets.length) {
            root.addPoolFromEditor()
            return
        }
        if (pool.name.length === 0 || !root.validStratumUrl(pool.url)) {
            root.poolEditorStatus = "Enter a pool name and a stratum+tcp:// or stratum+ssl:// address."
            return
        }
        const rows = root.miningPoolPresets.slice()
        rows[root.poolEditorIndex] = pool
        root.miningPoolPresets = rows
        root.selectedPoolKey = root.poolRowKey(pool, root.poolEditorIndex)
        root.persistMiningPoolPresets()
        root.poolEditorStatus = "Pool updated."
    }

    function removeSelectedPool() {
        if (root.poolEditorIndex < 0 || root.poolEditorIndex >= root.miningPoolPresets.length)
            return
        const rows = root.miningPoolPresets.slice()
        rows.splice(root.poolEditorIndex, 1)
        root.miningPoolPresets = rows
        root.poolEditorIndex = -1
        root.selectedPoolKey = ""
        root.persistMiningPoolPresets()
        if (root.miningPoolPresets.length > 0)
            root.loadPoolByIndex(Math.min(rows.length - 1, 0))
        else
            root.poolEditorStatus = "Pool removed."
    }

    function resetPoolPresets() {
        NuService.saveMiningPoolPresets([])
        root.refreshMiningPoolPresetsFromService()
        root.poolEditorStatus = "Default pools restored."
    }

    function benchmarkPools() {
        const rows = []
        const seen = {}
        for (let i = 0; i < root.miningPoolPresets.length; ++i) {
            const pool = root.miningPoolPresets[i]
            rows.push({
                poolNo: rows.length + 1,
                name: pool.name,
                url: pool.url,
                poolSoftware: root.shortPoolSoftware(pool.poolSoftware || "Unk. stratum"),
                color: pool.color,
                payoutAddress: pool.payoutAddress || "",
                password: pool.password || ""
            })
            seen[String(pool.url).toLowerCase()] = true
        }
        const customUrl = root.currentPoolUrl().trim()
        if (customUrl.length > 0 && !seen[customUrl.toLowerCase()]) {
            rows.push({ poolNo: rows.length + 1, name: "Custom", url: customUrl, poolSoftware: "Unk. stratum", color: "#d98534" })
        }
        return rows
    }

    function benchmarkSecondsPerPool() {
        const value = parseInt(benchmarkSeconds.text)
        return isNaN(value) ? 300 : Math.max(10, Math.min(86400, value))
    }

    function enforceBenchmarkSecondsMinimum() {
        const value = root.benchmarkSecondsPerPool()
        if (benchmarkSeconds.text !== String(value))
            benchmarkSeconds.text = String(value)
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
        if (minutes > 0)
            return minutes + "m " + String(secs).padStart(2, "0") + "s"
        return secs + "s"
    }

    function benchmarkEstimatedRuntime() {
        const starts = benchmarkPools().length * benchmarkCycles()
        return formatBenchmarkDuration(starts * benchmarkSecondsPerPool())
    }

    function benchmarkTimeLeftText() {
        return NuService.miningBenchmarkRunning ? NuService.miningBenchmarkEta : benchmarkEstimatedRuntime()
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

    function benchmarkMetricText(value, decimals, suffix) {
        value = Number(value)
        if (!Number.isFinite(value) || value < 0) return "-"
        let text = value.toFixed(decimals)
        text = text.replace(/0+$/, "").replace(/\.$/, "")
        return suffix && suffix.length > 0 ? text + " " + suffix : text
    }

    function benchmarkCompactDifficulty(value) {
        value = Number(value)
        if (!Number.isFinite(value) || value < 0) return "-"
        if (value === 0) return "0"
        if (value >= 1) return root.benchmarkMetricText(value, value >= 10 ? 1 : 2, "")
        if (value >= 0.001) return root.benchmarkMetricText(value * 1000, value >= 0.01 ? 1 : 2, "m")
        if (value >= 0.000001) return root.benchmarkMetricText(value * 1000000, value >= 0.00001 ? 1 : 2, "u")
        if (value >= 0.000000001) return root.benchmarkMetricText(value * 1000000000, value >= 0.00000001 ? 1 : 2, "n")
        return value.toExponential(1)
    }

    function benchmarkStatusText(row) {
        const explicit = String(row.statusDisplay || "")
        if (explicit.length > 0) return explicit
        const local = String(row.finishedAtLocal || "")
        const status = String(row.status || "-")
        if (status.toLowerCase() === "complete")
            return local.length > 0 ? "Complete " + local : "Complete"
        return local.length > 0 ? status + " " + local : status
    }

    function benchmarkWorkPerSecond(row) {
        const explicit = Number(row.acceptedDifficultyPerSecond)
        if (Number.isFinite(explicit) && explicit >= 0)
            return explicit
        const perMillisecond = Number(row.acceptedDifficultyPerMillisecond)
        if (Number.isFinite(perMillisecond) && perMillisecond >= 0)
            return perMillisecond * 1000
        const acceptedDifficulty = Number(row.acceptedDifficulty)
        const duration = Number(row.durationSeconds || 0)
        if (Number.isFinite(acceptedDifficulty) && acceptedDifficulty >= 0 && duration > 0)
            return acceptedDifficulty / duration
        return 0
    }

    function benchmarkWorkScore(row) {
        return root.benchmarkWorkPerSecond(row) * 1000000
    }

    function benchmarkAverageWorkScore() {
        const rows = NuService.miningBenchmarkRuns || []
        let total = 0
        let count = 0
        for (let i = 0; i < rows.length; ++i) {
            const value = root.benchmarkWorkScore(rows[i])
            if (Number.isFinite(value) && value >= 0) {
                total += value
                ++count
            }
        }
        return count > 0 ? total / count : 0
    }

    function benchmarkTableRows() {
        const rows = []
        const raw = NuService.miningBenchmarkRuns || []
        for (let i = 0; i < raw.length; ++i) {
            const row = raw[i]
            const poolNo = Number(row.poolNo || (Number(row.poolIndex || 0) + 1))
            const poolName = String(row.poolName || "-")
            const poolSoftware = root.normalizedPoolSoftwareForPool(poolName, row.poolUrl || "", row.poolSoftware || "Unk. stratum")
            const cycle = Number(row.cycle || 0)
            const duration = Number(row.durationSeconds || 0)
            const accepted = Number(row.accepted || 0)
            const acceptedDifficulty = Number(row.acceptedDifficulty || 0)
            const workScore = root.benchmarkWorkScore(row)
            const hashrateKh = Number(row.hashrateKh || 0)
            const pingMs = row.pingAvgMs === undefined ? -1 : Number(row.pingAvgMs)
            const finishedMs = Number(row.finishedAtMs || Date.parse(String(row.finishedAt || "")) || 0)
            rows.push({
                cells: [
                    String(cycle || "-"),
                    String(poolNo),
                    poolName,
                    poolSoftware,
                    root.formatBenchmarkDuration(duration),
                    String(Math.round(accepted)),
                    root.formatBenchmarkFixed(acceptedDifficulty * 1000000, 1),
                    root.formatBenchmarkFixed(workScore, 2),
                    root.formatBenchmarkFixed(hashrateKh, 2),
                    pingMs < 0 ? "-" : root.formatBenchmarkFixed(pingMs, 1)
                ],
                meta: {
                    runKey: String(poolNo) + ":" + String(cycle) + ":" + String(finishedMs) + ":" + poolName,
                    cycleSort: cycle,
                    poolNoSort: poolNo,
                    poolNameSort: poolName,
                    poolSoftwareSort: poolSoftware,
                    durationSort: duration,
                    acceptedSort: accepted,
                    difficultySort: acceptedDifficulty,
                    workSort: root.benchmarkWorkPerSecond(row),
                    hashrateSort: hashrateKh,
                    pingSort: pingMs < 0 ? 999999999 : pingMs,
                    cellTooltips: [
                        "Benchmark cycle number. The natural order is cycle first, then pool number.",
                        "Pool order in the benchmark run. The run loops through pools in this order.",
                        "Pool name. P2Pool is shown in Pool software instead of being repeated in the name.",
                        "Best known pool implementation. Unk. stratum means Nu could not reliably identify the backend software.",
                        "How long this pool was mined during this pass.",
                        "Raw accepted pool shares. Pools can assign different share difficulty, so this count is not an apples-to-apples speed metric.",
                        "Total accepted share difficulty for this pass, scaled by 1,000,000 to keep the column readable. This is the sum of the difficulty values attached to accepted shares.",
                        "Fairer speed score. Raw accepts are not comparable because pools can assign easier or harder shares. Nu sums accepted Submitted Diff values, uses the current target-equivalent minimum only when an accepted share has no matched Submitted Diff row, divides by elapsed seconds, then scales by 1,000,000. This is the closest apples-to-apples score available from the miner log; missing Submitted Diff values make it conservative rather than exact. Higher is better.",
                        "Miner-reported hashrate in kilohashes per second.",
                        pingMs < 0 ? "The server did not respond to Nu's ten-try endpoint latency check, or the endpoint refused the connection." : "Average of ten TCP connect latency checks before this mining pass. Nu does not send HTTP bytes to Stratum ports."
                    ]
                }
            })
        }
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

    function formatBenchmarkFixed(value, decimals) {
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
            const item = minerLogScroll && minerLogScroll.contentItem ? minerLogScroll.contentItem : null
            if (item && item.contentY !== undefined && item.contentHeight !== undefined)
                item.contentY = Math.max(0, item.contentHeight - item.height)
            Qt.callLater(function() { root.adjustingMinerLogTail = false })
        })
    }

    function followMinerLogHead() {
        Qt.callLater(function() {
            root.adjustingMinerLogTail = true
            minerLogText.cursorPosition = 0
            const item = minerLogScroll && minerLogScroll.contentItem ? minerLogScroll.contentItem : null
            if (item && item.contentY !== undefined)
                item.contentY = 0
            Qt.callLater(function() { root.adjustingMinerLogTail = false })
        })
    }

    function restoreMinerLogViewport(cursorPosition, contentY) {
        Qt.callLater(function() {
            if (root.minerLogAutoFollow)
                return
            root.adjustingMinerLogTail = true
            const maxCursor = Math.max(0, minerLogText.length)
            minerLogText.cursorPosition = Math.max(0, Math.min(maxCursor, cursorPosition))
            const item = minerLogScroll && minerLogScroll.contentItem ? minerLogScroll.contentItem : null
            if (item && item.contentY !== undefined && item.contentHeight !== undefined)
                item.contentY = Math.max(0, Math.min(contentY, Math.max(0, item.contentHeight - item.height)))
            Qt.callLater(function() { root.adjustingMinerLogTail = false })
        })
    }

    function leftPadNumber(value, width) {
        var out = String(value)
        while (out.length < width) out = " " + out
        return out
    }

    function numberedMinerLogText(lines) {
        let maxLineNumber = 1
        for (let i = 0; i < lines.length; ++i) {
            if (Number(lines[i].lineNumber) > maxLineNumber) maxLineNumber = Number(lines[i].lineNumber)
        }
        const width = String(maxLineNumber).length
        const out = []
        for (let j = 0; j < lines.length; ++j) {
            const number = Number(lines[j].lineNumber) > 0 ? root.leftPadNumber(Number(lines[j].lineNumber), width)
                                                           : root.leftPadNumber("-", width)
            out.push(number + " \u2502 " + String(lines[j].line || ""))
        }
        return out.join("\n") + "\n"
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
        let rawLines = raw.split(/\r?\n/)
        while (rawLines.length > 0 && rawLines[rawLines.length - 1].length === 0)
            rawLines.pop()
        let lines = []
        for (let rawIndex = 0; rawIndex < rawLines.length; ++rawIndex) {
            const lineNumber = NuService.minerLogLineNumbers && NuService.minerLogLineNumbers.length > rawIndex
                               ? Number(NuService.minerLogLineNumbers[rawIndex])
                               : rawIndex + 1
            lines.push({ lineNumber: lineNumber, line: rawLines[rawIndex] })
        }
        if (include !== false && remove !== false) {
            lines = lines.filter(function(line) {
                const text = String(line.line || "")
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
        return root.numberedMinerLogText(lines)
    }

    function updateMinerLogDisplayText() {
        const previousCursor = minerLogText ? minerLogText.cursorPosition : 0
        const item = minerLogScroll && minerLogScroll.contentItem ? minerLogScroll.contentItem : null
        const previousY = item && item.contentY !== undefined ? item.contentY : 0
        root.minerLogDisplayText = root.displayedMinerLog()
        if (root.minerLogAutoFollow && root.minerLogRecentFirst)
            root.followMinerLogHead()
        else if (root.minerLogAutoFollow)
            root.followMinerLogTail()
        else
            root.restoreMinerLogViewport(previousCursor, previousY)
    }

    function refreshMinerLogView() {
        if (!root.minerLogAutoFollow)
            return
        if (root.minerLogRecentFirst)
            root.followMinerLogHead()
        else
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
                    text: "Choose, add, or remove Defcoin pool presets. The selected stratum address is passed to the miner as the pool target; the payout address is passed as the username."
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                }

                NuDataTable {
                    id: poolTable
                    Layout.fillWidth: false
                    Layout.preferredWidth: Math.min(root.width > 0 ? Math.max(520, root.width - NuTokens.spaceXl * 2) : 1120,
                                                    Math.max(420, poolTable.naturalOuterWidth()))
                    Layout.maximumWidth: root.width > 0 ? Math.max(520, root.width - NuTokens.spaceXl * 2) : 1120
                    Layout.preferredHeight: Math.min(260,
                                                     Math.max(104,
                                                              poolTable.headerHeight()
                                                              + root.miningPoolPresets.length * poolTable.baseRowHeight()
                                                              + NuTokens.spaceSm * 2 + 2))
                    tableId: "miningPoolPresets"
                    emptyText: "No pool presets."
                    compact: true
                    fontPixelSize: Math.max(10, NuTokens.fontSmall - 1)
                    rowSelectionEnabled: true
                    plainClickSelectsRows: false
                    rowKeyMetaField: "key"
                    autoFitOnRowsChanged: true
                    autoFitOnFontChanged: true
                    shrinkToContent: true
                    fitColumnsToViewport: false
                    centerHeaderText: true
                    rowReorderEnabled: true
                    rowReorderColumn: 0
                    columns: ["No.", "Pool name", "Stratum address", "Pool software", "Payout", "Password"]
                    columnTypes: ["number", "text", "text", "text", "text", "text"]
                    columnMinimums: [38, 72, 130, 72, 48, 58]
                    columnMaximums: [48, 230, 390, 112, 420, 160]
                    columnSortMetaFields: ["noSort", "nameSort", "urlSort", "softwareSort", "payoutSort", "passwordSort"]
                    columnTooltips: [
                        "Pool order. Click and hold a number, then drag up or down to reorder the saved presets.",
                        "Display name used in Mining and Benchmark Pools.",
                        "Stratum endpoint passed to the miner with -o.",
                        "Best-known backend software for benchmark grouping.",
                        "Optional per-pool payout address. Inherit means Nu uses the general mining payout address.",
                        "Optional per-pool stratum password. Inherit means Nu uses the general mining password."
                    ]
                    rows: root.poolTableRows()
                    onRowActivated: function(row) {
                        root.loadPoolRow(row)
                        minerPool.text = String((row.meta || {}).url || "")
                        if (String((row.meta || {}).payoutAddress || "").length > 0)
                            minerPayout.text = String((row.meta || {}).payoutAddress || "")
                        if (String((row.meta || {}).password || "").length > 0)
                            minerPassword.text = String((row.meta || {}).password || "")
                    }
                    onRowSelectionChanged: function(keys) {
                        if (keys.length === 1) {
                            const index = root.poolIndexForKey(keys[0])
                            if (index >= 0)
                                root.loadPoolByIndex(index)
                        }
                    }
                    onRowReorderRequested: function(row, targetRow) {
                        const fromIndex = Number((row.meta || {}).index)
                        const toIndex = Number((targetRow.meta || {}).index)
                        if (Number.isFinite(fromIndex) && Number.isFinite(toIndex))
                            root.reorderPoolPreset(fromIndex, toIndex)
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 1040
                    columns: 4
                    rowSpacing: NuTokens.spaceSm
                    columnSpacing: NuTokens.spaceMd

                    Label { text: "Pool name"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: poolNameField
                        Layout.preferredWidth: 250
                        placeholderText: "Pool display name"
                        helpText: "Name shown in the preset table and benchmark results."
                    }

                    Label { text: "Pool software"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: poolSoftwareField
                        Layout.preferredWidth: 190
                        placeholderText: "P2Pool, UNOMP, or Unk. stratum"
                        helpText: "Best-known backend software for benchmark labeling."
                    }

                    Label { text: "Stratum address"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: poolStratumField
                        Layout.columnSpan: 3
                        Layout.fillWidth: true
                        placeholderText: "stratum+tcp://host-or-ip:port"
                        helpText: "Pool endpoint saved in the preset table."
                    }

                    Label { text: "Pool payout"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: poolPayoutField
                        Layout.fillWidth: true
                        placeholderText: "inherit general payout address"
                        helpText: "Optional per-pool payout address. Leave blank to inherit the general mining payout address."
                    }

                    Label { text: "Pool password"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: poolPasswordField
                        Layout.preferredWidth: 190
                        placeholderText: "inherit"
                        helpText: "Optional per-pool stratum password. Leave blank to inherit the general mining password."
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd
                    NuActionButton {
                        width: 112
                        text: "Use selected"
                        enabled: root.poolEditorIndex >= 0
                        helpText: "Use the selected preset as the current mining pool target."
                        onClicked: {
                            if (root.poolEditorIndex >= 0 && root.poolEditorIndex < root.miningPoolPresets.length) {
                                const pool = root.miningPoolPresets[root.poolEditorIndex]
                                minerPool.text = String(pool.url || "")
                                if (String(pool.payoutAddress || "").length > 0)
                                    minerPayout.text = String(pool.payoutAddress || "")
                                if (String(pool.password || "").length > 0)
                                    minerPassword.text = String(pool.password || "")
                            }
                        }
                    }
                    NuActionButton {
                        width: 94
                        text: "Add pool"
                        helpText: "Add the Name and Stratum address fields as a new preset."
                        onClicked: root.addPoolFromEditor()
                    }
                    NuActionButton {
                        width: 124
                        text: "Update selected"
                        enabled: root.poolEditorIndex >= 0
                        helpText: "Replace the selected preset with the editor fields."
                        onClicked: root.updateSelectedPool()
                    }
                    NuActionButton {
                        width: 118
                        text: "Remove selected"
                        enabled: root.poolEditorIndex >= 0
                        danger: true
                        helpText: "Remove the selected preset from the saved pool list."
                        onClicked: root.removeSelectedPool()
                    }
                    NuActionButton {
                        width: 112
                        text: "Reset defaults"
                        helpText: "Restore Nu's built-in Defcoin pool presets."
                        onClicked: root.resetPoolPresets()
                    }
                    Label {
                        width: 260
                        text: root.poolEditorStatus
                        color: root.poolEditorStatus.indexOf("Enter") === 0 || root.poolEditorStatus.indexOf("already") >= 0 ? NuTokens.stateError : NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WordWrap
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 1040
                    columns: 3
                    rowSpacing: NuTokens.spaceSm
                    columnSpacing: NuTokens.spaceMd

                    Label { text: "Current pool"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: minerPool
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        text: NuService.minerPoolUrl.length > 0 ? NuService.minerPoolUrl : "stratum+tcp://135.148.43.188:13371"
                        placeholderText: "stratum+tcp://host:port"
                        helpText: "Current stratum endpoint passed to the miner with -o. Use a preset above or type a custom target here."
                    }

                    Label { text: "Payout address"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
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

                    Label { text: "Password"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
                    NuTextField {
                        id: minerPassword
                        Layout.fillWidth: true
                        text: NuService.minerPassword.length > 0 ? NuService.minerPassword : "x"
                        placeholderText: "x"
                        helpText: "Stratum password passed with -p. Most Defcoin pools accept x."
                    }
                    Item { Layout.fillWidth: true }

                    NuActionButton {
                        Layout.preferredWidth: 150
                        text: "Save pool"
                        helpText: "Save the current pool URL, payout address, and password as the general mining settings."
                        onClicked: root.saveConfig()
                    }
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
                            text: "Runs each preset pool with the saved miner settings, adds the custom pool if it differs, checks Stratum endpoint latency before every run, and saves the latest chart and stats automatically."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    NuActionButton {
                        Layout.minimumWidth: 112
                        Layout.preferredWidth: 112
                        Layout.maximumWidth: 112
                        text: "Load old run"
                        helpText: "Load a previously autosaved benchmark JSON file and chart."
                        onClicked: NuService.loadMiningBenchmarkRun()
                    }
                    NuActionButton {
                        Layout.minimumWidth: 104
                        Layout.preferredWidth: 104
                        Layout.maximumWidth: 104
                        text: "Open folder"
                        helpText: "Open the benchmark autosave folder."
                        onClicked: NuService.openMiningBenchmarkFolder()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceSm

                    Label {
                        text: "Per pool"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        Layout.alignment: Qt.AlignVCenter
                    }
                    NuTextField {
                        id: benchmarkSeconds
                        Layout.preferredWidth: 58
                        Layout.maximumWidth: 58
                        text: "300"
                        validator: IntValidator { bottom: 10; top: 86400 }
                        helpText: "Seconds to mine on each pool before switching. Minimum is 10 seconds; lower entries are raised to 10. Default is 300 seconds."
                        onEditingFinished: root.enforceBenchmarkSecondsMinimum()
                        onAccepted: root.enforceBenchmarkSecondsMinimum()
                    }
                    Label {
                        text: "Cycles"
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        Layout.alignment: Qt.AlignVCenter
                    }
                    NuTextField {
                        id: benchmarkCycleCount
                        Layout.preferredWidth: 48
                        Layout.maximumWidth: 48
                        text: "3"
                        validator: IntValidator { bottom: 1; top: 100 }
                        helpText: "How many times to loop over the pool list. Default is three cycles."
                    }
                    NuMetricRow {
                        label: "Pools"
                        value: String(root.benchmarkPools().length)
                        labelMaximumWidth: 38
                        valueMaximumWidth: 34
                        helpText: "Preset pools plus the custom field when it is different from every preset."
                    }
                    NuMetricRow {
                        label: "Run"
                        value: root.benchmarkEstimatedRuntime()
                        labelMaximumWidth: 28
                        valueMaximumWidth: 104
                        helpText: "Configured pool time times the number of cycles and pools."
                    }
                    NuMetricRow {
                        label: "Left"
                        value: root.benchmarkTimeLeftText()
                        labelMaximumWidth: 28
                        valueMaximumWidth: 104
                        helpText: "Before a run starts this mirrors the estimated runtime. During a run it counts down using pool time plus observed restart overhead."
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 96
                        Layout.alignment: Qt.AlignVCenter
                        text: NuService.miningBenchmarkRunning ? NuService.miningBenchmarkStatus : " "
                        color: NuService.miningBenchmarkRunning ? NuTokens.accentSky : NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    NuActionButton {
                        Layout.minimumWidth: 118
                        Layout.preferredWidth: 118
                        Layout.maximumWidth: 118
                        text: NuService.miningBenchmarkRunning ? "Stop benchmark" : "Start benchmark"
                        primary: !NuService.miningBenchmarkRunning
                        danger: NuService.miningBenchmarkRunning
                        helpText: "Start or stop the full pool benchmark sequence."
                        onClicked: {
                            if (NuService.miningBenchmarkRunning) {
                                NuService.stopMiningBenchmark()
                                return
                            }
                            root.enforceBenchmarkSecondsMinimum()
                            root.saveConfig()
                            NuService.startMiningBenchmark(root.benchmarkPools(),
                                                           root.benchmarkSecondsPerPool(),
                                                           root.benchmarkCycles())
                        }
                    }
                    NuActionButton {
                        Layout.minimumWidth: 96
                        Layout.preferredWidth: 96
                        Layout.maximumWidth: 96
                        enabled: (NuService.miningBenchmarkRuns || []).length > 0
                        text: "Export stats"
                        helpText: "Export the current benchmark JSON stats file."
                        onClicked: NuService.exportMiningBenchmarkStats()
                    }
                    NuActionButton {
                        Layout.minimumWidth: 96
                        Layout.preferredWidth: 96
                        Layout.maximumWidth: 96
                        enabled: (NuService.miningBenchmarkRuns || []).length > 0
                        text: "Export chart"
                        helpText: "Export the current benchmark chart PNG."
                        onClicked: NuService.exportMiningBenchmarkChart()
                    }
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
                        label: "Avg work/s x1e6"
                        value: root.formatBenchmarkNumber(root.benchmarkAverageWorkScore(), 1)
                        helpText: "Average accepted share difficulty per second, scaled by 1,000,000 for readability. This is fairer than raw accepted shares because it normalizes pools that assign different share difficulty; when the miner log omits Submitted Diff for an accepted share, Nu uses the target-equivalent minimum as a conservative fallback."
                    }
                    NuMetricRow {
                        label: "Avg hashrate"
                        value: root.formatBenchmarkNumber(root.benchmarkAverage("hashrateKh"), 2) + " KH/s"
                        helpText: "Average parsed miner hashrate across completed runs."
                    }
                    NuMetricRow {
                        label: "Avg HTTPing"
                        value: root.formatBenchmarkNumber(root.benchmarkAverage("pingAvgMs"), 1) + " ms"
                        helpText: "Average of Nu's ten TCP-connect latency checks before each pool run. Nu does not send HTTP bytes to Stratum ports."
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 560
                    spacing: NuTokens.spaceMd

                    NuDataTable {
                        id: benchmarkResultsTable
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.minimumWidth: 620
                        Layout.preferredWidth: Math.min(860, Math.max(620, benchmarkResultsTable.naturalOuterWidth()))
                        Layout.preferredHeight: 560
                        tableId: "miningBenchmarkResults"
                        emptyText: "No completed benchmark rows yet."
                        compact: true
                        fontPixelSize: Math.max(10, NuTokens.fontSmall - 1)
                        forceMonospace: false
                        rowSelectionEnabled: true
                        plainClickSelectsRows: false
                        rowKeyMetaField: "runKey"
                        autoFitOnRowsChanged: true
                        autoFitOnFontChanged: true
                        shrinkToContent: true
                        fitColumnsToViewport: false
                        centerHeaderText: true
                        defaultSortColumn: 0
                        defaultSortAscending: true
                    columns: ["Cycle", "Pool\nNo.", "Pool", "Pool\nsoftware", "Dur", "Accepted", "Diff\nx1e6", "Work/s\nx1e6", "Hashrate\n(KH/s)", "HTTPing\n(ms)"]
                    columnTypes: ["number", "number", "text", "text", "duration", "number", "number", "number", "number", "number"]
                    columnMinimums: [48, 48, 82, 78, 46, 64, 64, 78, 78, 68]
                    columnMaximums: [62, 62, 160, 112, 70, 84, 84, 104, 104, 86]
                        columnSortMetaFields: ["cycleSort", "poolNoSort", "poolNameSort", "poolSoftwareSort", "durationSort", "acceptedSort", "difficultySort", "workSort", "hashrateSort", "pingSort"]
                        columnTooltips: [
                            "Benchmark cycle number. The natural order is cycle first, then pool number.",
                            "Pool order in the benchmark run.",
                            "Pool name without repeating P2Pool when Pool software already says P2Pool.",
                            "Best known pool backend software.",
                            "Mining duration for this pool pass.",
                            "Raw accepted pool shares. Different share difficulty makes this diagnostic, not a fair speed comparison.",
                            "Total accepted share difficulty for this pass, scaled by 1,000,000 to keep the column readable. It sums the difficulty values attached to accepted shares.",
                            "Fairer speed score. Raw accepts are not comparable because pools can assign easier or harder shares. Nu sums accepted Submitted Diff values, uses the current target-equivalent minimum only when an accepted share has no matched Submitted Diff row, divides by elapsed seconds, then scales by 1,000,000. This is the closest apples-to-apples score available from the miner log; missing Submitted Diff values make it conservative rather than exact. Higher is better.",
                            "Miner-reported hashrate in kilohashes per second.",
                            "Average endpoint latency before the pool pass. A dash means the endpoint did not respond."
                        ]
                        rows: root.benchmarkTableRows()
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1060
                        Layout.minimumWidth: 320
                        Layout.fillHeight: true
                        Layout.preferredHeight: 560
                        radius: NuTokens.radiusMedium
                        color: NuTokens.backgroundBase
                        border.color: NuTokens.lineSubtle
                        clip: true

                        Image {
                            id: benchmarkChartImage
                            anchors.fill: parent
                            anchors.margins: NuTokens.spaceSm
                            source: NuService.miningBenchmarkChartSource
                            fillMode: Image.PreserveAspectFit
                            cache: false
                            visible: source.toString().length > 0
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: benchmarkChartImage.visible ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: benchmarkChartImage.visible
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    NuService.copyMiningBenchmarkChartImage()
                                    return
                                }
                                benchmarkChartWindow.show()
                                benchmarkChartWindow.raise()
                                benchmarkChartWindow.requestActivate()
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            width: parent.width - NuTokens.spaceXl * 2
                            visible: NuService.miningBenchmarkChartSource.length === 0
                            text: "The saved benchmark chart will appear here after the first chart is written."
                            color: NuTokens.textSecondary
                            font.pixelSize: NuTokens.fontSmall
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
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
                        text: "Output focus"
                        checked: root.minerLogAutoFollow
                        helpText: "Keep the newest miner output in view. With latest output on top, this focuses the first line; otherwise it follows the bottom tail."
                        onToggled: {
                            root.minerLogAutoFollow = checked
                            root.updateMinerLogDisplayText()
                        }
                    }
                    NuCheckBox {
                        text: "Latest output on top"
                        checked: root.minerLogRecentFirst
                        helpText: "Show newest miner output at the top of the monitor."
                        onToggled: {
                            root.minerLogRecentFirst = checked
                            root.updateMinerLogDisplayText()
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
                            root.updateMinerLogDisplayText()
                        }
                        onActivated: function(index) {
                            const value = root.minerLogPresetValue(root.minerLogFilterPresetModel[index])
                            editText = value
                            root.minerLogFilterPattern = value
                            root.updateMinerLogDisplayText()
                        }
                        onActiveFocusChanged: if (!activeFocus) {
                            root.minerLogFilterPattern = editText.substring(0, 160)
                            root.updateMinerLogDisplayText()
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
                            root.updateMinerLogDisplayText()
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
                        text: root.minerLogDisplayText
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
                            if (!root.minerLogAutoFollow)
                                return
                            if (root.minerLogRecentFirst) {
                                root.followMinerLogHead()
                                return
                            }
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

	    Window {
	        id: benchmarkChartWindow
	        minimumWidth: 960
	        minimumHeight: 540
	        title: "Defcoin pool benchmark chart"
	        color: NuTokens.backgroundBase
	        modality: Qt.NonModal
	        Component.onCompleted: {
	            width = 1600
	            height = 900
	        }
	        Image {
	            anchors.fill: parent
	            anchors.margins: NuTokens.spaceLg
	            source: NuService.miningBenchmarkChartSource
	            fillMode: Image.PreserveAspectFit
	            cache: false
	        }
	        MouseArea {
	            anchors.fill: parent
	            acceptedButtons: Qt.RightButton
	            onClicked: NuService.copyMiningBenchmarkChartImage()
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
