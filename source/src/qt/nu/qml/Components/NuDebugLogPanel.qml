import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import Defcoin.Nu 1.0

import "../Theme"

ColumnLayout {
    id: root
    spacing: NuTokens.spaceSm

    property int logFontSize: NuTokens.fontLog
    property string logFilterError: ""
    property int shownLogLineCount: 0
    property var logFilterPresetModel: []
    property bool logAutoFollow: true
    property bool logRecentFirst: false
    property bool adjustingLogScroll: false

    function logVerbosityName(level) {
        const names = ["All details", "Standard", "Important", "Warnings"]
        const index = Math.max(0, Math.min(3, Math.round(level)))
        return names[index]
    }

    function safeLogRegex(pattern) {
        const clean = String(pattern || "")
        if (clean.length === 0) return null
        if (clean.length > 160) {
            root.logFilterError = "Regex filters are limited to 160 characters."
            return false
        }
        try {
            return new RegExp(clean, "i")
        } catch (error) {
            root.logFilterError = "Malformed regex: " + error.message
            return false
        }
    }

    function logLineBucket(line) {
        const text = String(line || "").toLowerCase()
        if (text.indexOf("fatal") >= 0 || text.indexOf("crash") >= 0 || text.indexOf("error") >= 0
                || text.indexOf("failed") >= 0 || text.indexOf("warning") >= 0
                || text.indexOf("not defcoin-prefixed") >= 0 || text.indexOf("disconnecting before address relay") >= 0
                || text.indexOf("disconnecting outbound peer") >= 0 || text.indexOf("old chain") >= 0
                || text.indexOf("reject") >= 0 || text.indexOf("banned") >= 0 || text.indexOf("timeout") >= 0
                || text.indexOf("orphan") >= 0 || text.indexOf("reorg") >= 0 || text.indexOf("stale") >= 0) {
            return 3
        }
        if (text.indexOf("----- nu startup diagnostics") >= 0
                || text.indexOf("nu startup: frontend application launched") >= 0
                || text.indexOf("nu startup: network preferences") >= 0
                || text.indexOf("nu startup: wallet selected") >= 0
                || text.indexOf("nu startup: rpc credentials are available") >= 0
                || text.indexOf("starting backend") >= 0
                || text.indexOf("backend rpc is connected") >= 0
                || text.indexOf("init message: done loading") >= 0
                || text.indexOf("loaded best chain") >= 0
                || text.indexOf("nbestheight") >= 0
                || text.indexOf("leaving initialblockdownload") >= 0
                || text.indexOf("new outbound peer connected") >= 0
                || text.indexOf("addresses found from dns seeds") >= 0) {
            return 2
        }
        if (text.indexOf("init message:") >= 0 || text.indexOf("wallet completed loading") >= 0
                || text.indexOf("wallet file version") >= 0 || text.indexOf("keys:") >= 0
                || text.indexOf("loading addresses from dns seed") >= 0
                || text.indexOf("adding fixed seed nodes") >= 0
                || text.indexOf("bound to ") >= 0 || text.indexOf("loaded ") >= 0
                || text.indexOf("thread start") >= 0 || text.indexOf("thread exit") >= 0
                || text.indexOf("updatetip:") >= 0 || text.indexOf("addtowallet") >= 0
                || text.indexOf("submitting wtx") >= 0 || text.indexOf("setting") >= 0
                || text.indexOf("traffic") >= 0 || text.indexOf("mempool") >= 0
                || text.indexOf("p2p") >= 0 || text.indexOf("peer") >= 0
                || text.indexOf("rpc") >= 0 || text.indexOf("connect") >= 0) {
            return 1
        }
        return 0
    }

    function leftPadNumber(value, width) {
        var out = String(value)
        while (out.length < width) out = " " + out
        return out
    }

    function numberedLogText(lines) {
        const out = []
        const viewWidth = String(Math.max(1, lines.length)).length
        var maxLineNumber = 1
        for (let maxIndex = 0; maxIndex < lines.length; ++maxIndex) {
            if (lines[maxIndex].lineNumber > maxLineNumber) maxLineNumber = lines[maxIndex].lineNumber
        }
        const debugWidth = String(maxLineNumber).length
        for (let i = 0; i < lines.length; ++i) {
            const debugLineNumber = lines[i].lineNumber > 0 ? root.leftPadNumber(lines[i].lineNumber, debugWidth) : root.leftPadNumber("-", debugWidth)
            const viewLineNumber = root.logRecentFirst ? lines.length - i : i + 1
            out.push(root.leftPadNumber(viewLineNumber, viewWidth) + " \u2502 " + debugLineNumber + " \u2502 " + String(lines[i].line || ""))
        }
        return out.join("\n")
    }

    function logFilterPresets() {
        const presets = [
            "[type search term here]",
            "Error",
            "Warning",
            "failed|timeout|disconnect",
            "valid fork|stale|reorg|orphan",
            "scriptPubKey Manager|sqlwallet|descriptor",
            "wallet|loadwallet|createwallet|AddToWallet",
            "block index|Reindex|FlushStateToDisk",
            "witness|NODE_WITNESS|SegWit",
            "RPC|ThreadRPCServer|HTTP",
            "connect|disconnect|timeout|socket",
            "fast sync|UDP|TCP",
            "UpdateTip",
            "seednode|dns seed|fixed seed",
            "receive version message",
            "version "
        ]
        const last = String(NuService.logLastSearchPattern || "").trim()
        if (last.length > 0 && presets.indexOf(last) < 0) presets.push("Last: " + last)
        return presets
    }

    function refreshLogFilterPresets() {
        root.logFilterPresetModel = root.logFilterPresets()
    }

    function logPresetValue(label) {
        const text = String(label || "")
        if (text === "[type search term here]") return ""
        if (text.indexOf("Last: ") === 0) return text.substring(6)
        return text
    }

    function setLogSearchPattern(pattern) {
        NuService.logSearchPattern = String(pattern || "").substring(0, 160)
        root.refreshLogFilterPresets()
    }

    function filteredLogText() {
        root.logFilterError = ""
        const search = safeLogRegex(NuService.logSearchPattern)
        const remove = safeLogRegex(NuService.logRemovePattern)
        const out = []
        if (search === false || remove === false) {
            for (let allIndex = 0; allIndex < NuService.logLines.length; ++allIndex) {
                const allLineNumber = NuService.logLineNumbers && NuService.logLineNumbers.length > allIndex ? Number(NuService.logLineNumbers[allIndex]) : 0
                out.push({ "lineNumber": allLineNumber, "line": NuService.logLines[allIndex] })
            }
            root.shownLogLineCount = out.length
            return root.numberedLogText(out)
        }
        const level = Math.max(0, Math.min(3, NuService.logVerbosity))
        for (let i = 0; i < NuService.logLines.length; ++i) {
            const line = String(NuService.logLines[i])
            if (level > 0 && root.logLineBucket(line) < level) continue
            if (search && !search.test(line)) continue
            if (remove && remove.test(line)) continue
            const lineNumber = NuService.logLineNumbers && NuService.logLineNumbers.length > i ? Number(NuService.logLineNumbers[i]) : 0
            out.push({ "lineNumber": lineNumber, "line": line })
        }
        root.shownLogLineCount = out.length
        if (out.length === 0) {
            return NuService.logLines.length > 0
                   ? "No debug log lines match the current Filter, Remove, and Verbosity settings."
                   : "No debug log lines have been recorded yet. Nu startup diagnostics should appear here shortly."
        }
        if (root.logRecentFirst)
            out.reverse()
        return root.numberedLogText(out)
    }

    function updateLogText() {
        const oldCursor = debugLogText.cursorPosition
        const oldSelectionStart = debugLogText.selectionStart
        const oldSelectionEnd = debugLogText.selectionEnd
        const hadSelection = oldSelectionStart !== oldSelectionEnd
        debugLogText.text = root.filteredLogText()
        debugLogText.cursorPosition = Math.min(oldCursor, debugLogText.length)
        if (hadSelection)
            debugLogText.select(Math.min(oldSelectionStart, debugLogText.length), Math.min(oldSelectionEnd, debugLogText.length))
        else if (root.logAutoFollow) {
            if (root.logRecentFirst)
                root.followLogHead()
            else
                root.followLogTail()
        }
    }

    function followLogTail() {
        Qt.callLater(function() {
            root.adjustingLogScroll = true
            debugLogText.cursorPosition = debugLogText.length
            Qt.callLater(function() { root.adjustingLogScroll = false })
        })
    }

    function followLogHead() {
        Qt.callLater(function() {
            root.adjustingLogScroll = true
            debugLogText.cursorPosition = 0
            Qt.callLater(function() { root.adjustingLogScroll = false })
        })
    }

    function findInLog(backward) {
        const needle = String(logFindField.text || "")
        if (needle.length === 0) return
        const hay = debugLogText.text
        const lowerHay = hay.toLowerCase()
        const lowerNeedle = needle.toLowerCase()
        var index = -1
        if (backward) {
            const startBack = Math.max(0, debugLogText.selectionStart - 1)
            index = lowerHay.lastIndexOf(lowerNeedle, startBack)
            if (index < 0) index = lowerHay.lastIndexOf(lowerNeedle)
        } else {
            const startForward = Math.max(0, debugLogText.selectionEnd)
            index = lowerHay.indexOf(lowerNeedle, startForward)
            if (index < 0) index = lowerHay.indexOf(lowerNeedle)
        }
        if (index >= 0) {
            debugLogText.forceActiveFocus()
            debugLogText.select(index, index + needle.length)
            debugLogText.cursorPosition = index + needle.length
        }
    }

    Component.onCompleted: {
        root.refreshLogFilterPresets()
        root.updateLogText()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: NuTokens.spaceSm

        Label { text: "Verbosity"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
        Basic.Slider {
            id: logVerbositySlider
            Layout.preferredWidth: 132
            from: 0
            to: 3
            stepSize: 1
            value: NuService.logVerbosity
            onMoved: NuService.logVerbosity = Math.round(value)
        }
        Label { text: root.logVerbosityName(NuService.logVerbosity); color: NuTokens.textPrimary; font.pixelSize: NuTokens.fontSmall }
        Label { text: "Lines: " + root.shownLogLineCount; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
        NuCheckBox {
            text: "Output focus"
            checked: root.logAutoFollow
            helpText: "Keep newest debug log output in view. With latest output on top, this focuses the first line; otherwise it follows the bottom tail."
            onToggled: {
                root.logAutoFollow = checked
                if (checked) {
                    if (root.logRecentFirst)
                        root.followLogHead()
                    else
                        root.followLogTail()
                }
            }
        }
        NuCheckBox {
            text: "Latest output on top"
            checked: root.logRecentFirst
            helpText: "Show newest debug log output at the top."
            onToggled: {
                root.logRecentFirst = checked
                root.updateLogText()
            }
        }
        Label {
            Layout.fillWidth: true
            text: root.logFilterError
            color: NuTokens.stateWarning
            font.pixelSize: NuTokens.fontSmall
            elide: Text.ElideRight
        }
        NuActionButton { text: "A-"; Layout.preferredWidth: 54; onClicked: root.logFontSize = Math.max(9, root.logFontSize - 1) }
        NuActionButton { text: "A+"; Layout.preferredWidth: 54; onClicked: root.logFontSize = Math.min(22, root.logFontSize + 1) }
        NuActionButton { text: "Copy shown"; Layout.preferredWidth: 118; onClicked: NuService.copyText(debugLogText.text) }
        NuActionButton { text: "Save log"; Layout.preferredWidth: 104; onClicked: NuService.saveLaunchLog(debugLogText.text) }
        NuActionButton { text: "Open debug.log"; Layout.preferredWidth: 148; onClicked: NuService.openDebugLog() }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: NuTokens.spaceSm

        Label { text: "Filter:"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
        NuComboBox {
            id: logSearchFilter
            Layout.preferredWidth: 260
            editable: true
            model: root.logFilterPresetModel
            currentIndex: 0
            helpText: "Show only matching log lines. Choose a useful regex preset or type your own."
            Component.onCompleted: editText = NuService.logSearchPattern
            onAccepted: root.setLogSearchPattern(editText)
            onActivated: function(index) {
                const value = root.logPresetValue(root.logFilterPresetModel[index])
                editText = value
                root.setLogSearchPattern(value)
            }
            onActiveFocusChanged: if (!activeFocus) root.setLogSearchPattern(editText)
        }
        Label { text: "Remove:"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
        NuTextField {
            id: logRemoveFilter
            Layout.preferredWidth: 180
            text: NuService.logRemovePattern
            maximumLength: 160
            placeholderText: "hide regex"
            helpText: "Hide matching lines after Filter is applied."
            onEditingFinished: NuService.logRemovePattern = text
        }
        Label { text: "Find:"; color: NuTokens.textSecondary; font.pixelSize: NuTokens.fontSmall }
        NuTextField {
            id: logFindField
            Layout.fillWidth: true
            Layout.minimumWidth: 170
            maximumLength: 120
            placeholderText: "Find in shown log"
            onAccepted: root.findInLog(false)
        }
        NuActionButton { text: "Prev"; Layout.preferredWidth: 72; onClicked: root.findInLog(true) }
        NuActionButton { text: "Next"; Layout.preferredWidth: 72; onClicked: root.findInLog(false) }
    }

    Basic.ScrollView {
        id: debugLogScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        Basic.ScrollBar.vertical.policy: Basic.ScrollBar.AlwaysOn
        Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOn

        TextArea {
            id: debugLogText
            width: Math.max(implicitWidth, debugLogScroll.availableWidth)
            height: Math.max(implicitHeight, debugLogScroll.availableHeight)
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            wrapMode: Text.NoWrap
            color: NuTokens.textPrimary
            selectionColor: NuTokens.lineStrong
            selectedTextColor: NuTokens.textInverse
            font.family: NuTokens.monoFont
            font.pixelSize: root.logFontSize
            background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle }

            Shortcut {
                sequences: [StandardKey.Copy]
                enabled: debugLogText.activeFocus && debugLogText.selectedText.length > 0
                onActivated: NuService.copyText(debugLogText.selectedText)
            }
        }
    }

    Connections {
        target: NuService
        function onLogChanged() { root.updateLogText() }
        function onSettingsChanged() {
            logVerbositySlider.value = NuService.logVerbosity
            logSearchFilter.editText = NuService.logSearchPattern
            logRemoveFilter.text = NuService.logRemovePattern
            root.refreshLogFilterPresets()
            root.updateLogText()
        }
    }
}
