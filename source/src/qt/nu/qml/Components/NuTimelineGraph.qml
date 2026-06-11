import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Theme"

Item {
    id: root
    implicitHeight: 360

    property bool detailsMode: false
    property color receivedColor: NuTokens.dataReceived
    property color sentColor: NuTokens.dataSent
    property color tcpReceivedColor: "#138a50"
    property color tcpSentColor: "#2166d1"
    property color fastSyncUdpReceivedColor: "#3fc47c"
    property color fastSyncUdpSentColor: "#69a8ff"
    property color quickCloneReceivedColor: "#0d6b57"
    property color quickCloneSentColor: "#174ea6"
    property var samples: []
    property real windowStart: 0
    property real windowEnd: 1
    readonly property real visibleStart: Math.max(0, Math.min(windowStart, windowEnd - 0.01))
    readonly property real visibleEnd: Math.min(1, Math.max(windowEnd, visibleStart + 0.01))

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        property var hoverSample: null
        property real hoverX: 0
        property real hoverY: 0

        function visibleSamples() {
            if (!root.samples || root.samples.length < 2) return []
            const first = root.samples[0].seconds
            const last = root.samples[root.samples.length - 1].seconds
            const span = Math.max(1, last - first)
            const start = first + span * root.visibleStart
            const end = first + span * root.visibleEnd
            let out = []
            for (let i = 0; i < root.samples.length; ++i) {
                const sample = root.samples[i]
                if (sample.seconds >= start && sample.seconds <= end) out.push(sample)
            }
            if (out.length < 2) return root.samples.slice(Math.max(0, root.samples.length - 2))
            return out
        }

        function safeRate(value) {
            const n = Number(value)
            return isNaN(n) ? 0 : Math.max(0, n)
        }

        function componentRate(sample, key) {
            if (!sample) return 0
            if (sample[key] !== undefined) return safeRate(sample[key])
            return 0
        }

        function groupTotal(sample, components) {
            let total = 0
            for (let i = 0; i < components.length; ++i)
                total += componentRate(sample, components[i].key)
            return total
        }

        function formatRate(value) {
            value = Math.max(0, Number(value) || 0)
            let bits = value * 8
            if (bits >= 1000 * 1000 * 1000) return (bits / (1000 * 1000 * 1000)).toFixed(2) + " Gb/s"
            if (bits >= 1000 * 1000) return (bits / (1000 * 1000)).toFixed(bits >= 100 * 1000 * 1000 ? 0 : 1) + " Mb/s"
            if (bits >= 1000) return (bits / 1000).toFixed(bits >= 100 * 1000 ? 0 : 1) + " Kb/s"
            return Math.round(bits) + " b/s"
        }

        function formatSampleTime(sample) {
            if (!sample || !sample.timestampMs) return "Local time unavailable"
            return new Date(sample.timestampMs).toLocaleString()
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = NuTokens.panelBase
            ctx.fillRect(0, 0, width, height)
            ctx.strokeStyle = NuTokens.lineSubtle
            ctx.lineWidth = 1
            for (let y = 0; y <= 4; y++) {
                const py = Math.round((height - 1) * y / 4)
                ctx.beginPath()
                ctx.moveTo(0, py)
                ctx.lineTo(width, py)
                ctx.stroke()
            }

            const visible = visibleSamples()
            if (!visible || visible.length < 2) {
                ctx.fillStyle = NuTokens.textSecondary
                ctx.font = "15px sans-serif"
                ctx.fillText("Waiting for live network traffic samples...", 18, 32)
                return
            }

            const receivedComponents = [
                { key: "tcpReceived", label: "Rec'd TCP", color: root.tcpReceivedColor },
                { key: "fastSyncUdpReceived", label: "Rec'd FS UDP", color: root.fastSyncUdpReceivedColor },
                { key: "quickCloneReceived", label: "Rec'd QC UDP", color: root.quickCloneReceivedColor }
            ]
            const sentComponents = [
                { key: "tcpSent", label: "Sent TCP", color: root.tcpSentColor },
                { key: "fastSyncUdpSent", label: "Sent FS UDP", color: root.fastSyncUdpSentColor },
                { key: "quickCloneSent", label: "Sent QC UDP", color: root.quickCloneSentColor }
            ]
            const groups = [
                { label: "Rec'd", components: receivedComponents, totalKey: "received", color: root.receivedColor },
                { label: "Sent", components: sentComponents, totalKey: "sent", color: root.sentColor }
            ]

            let firstSecond = visible[0].seconds
            let lastSecond = visible[visible.length - 1].seconds
            let span = Math.max(1, lastSecond - firstSecond)
            let maxValue = 1
            let peakReceived = visible[0]
            let peakSent = visible[0]
            for (let i = 0; i < visible.length; ++i) {
                const recTotal = root.detailsMode ? groupTotal(visible[i], receivedComponents) : safeRate(visible[i].received)
                const sentTotal = root.detailsMode ? groupTotal(visible[i], sentComponents) : safeRate(visible[i].sent)
                maxValue = Math.max(maxValue, recTotal, sentTotal)
                if (recTotal > (root.detailsMode ? groupTotal(peakReceived, receivedComponents) : safeRate(peakReceived.received))) peakReceived = visible[i]
                if (sentTotal > (root.detailsMode ? groupTotal(peakSent, sentComponents) : safeRate(peakSent.sent))) peakSent = visible[i]
            }

            const plotTop = 8
            const plotBottom = height - 18

            function xFor(sample) {
                return (sample.seconds - firstSecond) / span * width
            }
            function yFor(value) {
                const normalized = Math.max(0, Math.min(1, safeRate(value) / Math.max(1, maxValue)))
                return Math.max(plotTop, Math.min(plotBottom - 1, plotBottom - 1 - normalized * (plotBottom - plotTop - 28)))
            }
            function drawLine(key, color, lineWidth, dashPattern, alpha) {
                ctx.save()
                ctx.beginPath()
                ctx.rect(0, plotTop, width, plotBottom - plotTop)
                ctx.clip()
                ctx.strokeStyle = color
                ctx.lineWidth = lineWidth
                ctx.globalAlpha = alpha
                if (ctx.setLineDash) ctx.setLineDash(dashPattern)
                ctx.beginPath()
                for (let i = 0; i < visible.length; ++i) {
                    const x = xFor(visible[i])
                    const y = yFor(visible[i][key])
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.stroke()
                if (ctx.setLineDash) ctx.setLineDash([])
                ctx.restore()
            }
            function componentTotal(component) {
                let total = 0
                for (let i = 0; i < visible.length; ++i)
                    total += componentRate(visible[i], component.key)
                return total
            }
            function groupPeak(group) {
                let peak = 0
                for (let i = 0; i < visible.length; ++i)
                    peak = Math.max(peak, groupTotal(visible[i], group.components))
                return peak
            }
            function drawStackGroup(group) {
                let ordered = group.components.slice()
                ordered.sort(function(a, b) { return componentTotal(b) - componentTotal(a) })
                let baseline = []
                for (let i = 0; i < visible.length; ++i)
                    baseline.push(0)

                ctx.save()
                ctx.beginPath()
                ctx.rect(0, plotTop, width, plotBottom - plotTop)
                ctx.clip()
                for (let c = 0; c < ordered.length; ++c) {
                    const component = ordered[c]
                    ctx.beginPath()
                    for (let i = 0; i < visible.length; ++i) {
                        const upper = baseline[i] + componentRate(visible[i], component.key)
                        const x = xFor(visible[i])
                        const y = yFor(upper)
                        if (i === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    for (let i = visible.length - 1; i >= 0; --i) {
                        const x = xFor(visible[i])
                        const y = yFor(baseline[i])
                        ctx.lineTo(x, y)
                    }
                    ctx.closePath()
                    ctx.fillStyle = component.color
                    ctx.globalAlpha = 0.68
                    ctx.fill()
                    ctx.globalAlpha = 0.95
                    ctx.strokeStyle = component.color
                    ctx.lineWidth = 1
                    ctx.stroke()
                    for (let i = 0; i < visible.length; ++i)
                        baseline[i] += componentRate(visible[i], component.key)
                }
                ctx.globalAlpha = 1.0
                ctx.strokeStyle = group.color
                ctx.lineWidth = 2.4
                ctx.beginPath()
                for (let i = 0; i < visible.length; ++i) {
                    const x = xFor(visible[i])
                    const y = yFor(groupTotal(visible[i], group.components))
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.stroke()
                ctx.restore()
            }
            function peakLabel(text, x, y) {
                ctx.save()
                ctx.font = "13px sans-serif"
                const metrics = ctx.measureText(text)
                const padX = 5
                const padY = 4
                const boxX = Math.max(4, Math.min(width - metrics.width - padX * 2 - 4, x))
                const boxY = Math.max(4, Math.min(height - 22, y - 14))
                ctx.fillStyle = "rgba(255, 255, 255, 0.86)"
                ctx.strokeStyle = "rgba(17, 17, 17, 0.18)"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.rect(boxX, boxY, metrics.width + padX * 2, 18 + padY)
                ctx.fill()
                ctx.stroke()
                ctx.fillStyle = NuTokens.textPrimary
                ctx.fillText(text, boxX + padX, boxY + 15)
                ctx.restore()
            }
            function legendSwatch(x, y, color, label) {
                ctx.fillStyle = color
                ctx.globalAlpha = 0.84
                ctx.fillRect(x, y - 9, 22, 8)
                ctx.globalAlpha = 1.0
                ctx.fillStyle = NuTokens.textPrimary
                ctx.font = "12px sans-serif"
                ctx.fillText(label, x + 28, y)
            }

            if (root.detailsMode) {
                const orderedGroups = groups.slice()
                orderedGroups.sort(function(a, b) { return groupPeak(b) - groupPeak(a) })
                for (let i = 0; i < orderedGroups.length; ++i)
                    drawStackGroup(orderedGroups[i])
            } else {
                drawLine("received", root.receivedColor, 2.5, [], 1.0)
                drawLine("sent", root.sentColor, 2.5, [], 1.0)
            }

            const peakReceivedValue = root.detailsMode ? groupTotal(peakReceived, receivedComponents) : safeRate(peakReceived.received)
            const peakSentValue = root.detailsMode ? groupTotal(peakSent, sentComponents) : safeRate(peakSent.sent)
            const receivedLabelY = Math.max(24, Math.min(height - 48, yFor(peakReceivedValue) - 10))
            const sentLabelY = Math.max(receivedLabelY + 18, Math.min(height - 24, yFor(peakSentValue) + 20))
            peakLabel("Peak rec'd " + formatRate(peakReceivedValue), Math.min(width - 170, xFor(peakReceived) + 8), receivedLabelY)
            peakLabel("Peak sent " + formatRate(peakSentValue), Math.min(width - 160, xFor(peakSent) + 8), sentLabelY)

            if (root.detailsMode) {
                const legendX = Math.max(12, width - 560)
                legendSwatch(legendX, 18, root.tcpReceivedColor, "Rec'd TCP")
                legendSwatch(legendX + 118, 18, root.fastSyncUdpReceivedColor, "Rec'd FS UDP")
                legendSwatch(legendX + 258, 18, root.quickCloneReceivedColor, "Rec'd QC UDP")
                legendSwatch(legendX, 38, root.tcpSentColor, "Sent TCP")
                legendSwatch(legendX + 118, 38, root.fastSyncUdpSentColor, "Sent FS UDP")
                legendSwatch(legendX + 258, 38, root.quickCloneSentColor, "Sent QC UDP")
            } else {
                const legendX = Math.max(12, width - 250)
                legendSwatch(legendX, 18, root.receivedColor, "Rec'd total")
                legendSwatch(legendX + 126, 18, root.sentColor, "Sent total")
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: (mouse) => {
                const visible = canvas.visibleSamples()
                if (!visible || visible.length < 1) {
                    canvas.hoverSample = null
                    return
                }
                let best = visible[0]
                let bestDistance = width
                const first = visible[0].seconds
                const last = visible[visible.length - 1].seconds
                const span = Math.max(1, last - first)
                for (let i = 0; i < visible.length; ++i) {
                    const sx = (visible[i].seconds - first) / span * width
                    const distance = Math.abs(sx - mouse.x)
                    if (distance < bestDistance) {
                        bestDistance = distance
                        best = visible[i]
                    }
                }
                canvas.hoverSample = best
                canvas.hoverX = mouse.x
                canvas.hoverY = mouse.y
                canvas.requestPaint()
            }
            onExited: canvas.hoverSample = null
        }

        Rectangle {
            visible: canvas.hoverSample !== null
            x: Math.min(parent.width - width - 8, Math.max(8, canvas.hoverX + 12))
            y: Math.min(parent.height - height - 8, Math.max(8, canvas.hoverY + 12))
            width: hoverText.implicitWidth + 18
            height: hoverText.implicitHeight + 12
            radius: NuTokens.radiusSmall
            color: NuTokens.inversePanel
            border.color: NuTokens.lineStrong

            Label {
                id: hoverText
                anchors.centerIn: parent
                color: NuTokens.textInverse
                font.pixelSize: NuTokens.fontSmall
                text: canvas.hoverSample
                      ? (root.detailsMode
                         ? (canvas.formatSampleTime(canvas.hoverSample)
                            + "\nRec'd total " + canvas.formatRate(canvas.groupTotal(canvas.hoverSample, [
                                { key: "tcpReceived" }, { key: "fastSyncUdpReceived" }, { key: "quickCloneReceived" }
                            ]))
                            + " | TCP " + canvas.formatRate(canvas.componentRate(canvas.hoverSample, "tcpReceived"))
                            + " | FS UDP " + canvas.formatRate(canvas.componentRate(canvas.hoverSample, "fastSyncUdpReceived"))
                            + " | QC UDP " + canvas.formatRate(canvas.componentRate(canvas.hoverSample, "quickCloneReceived"))
                            + "\nSent total " + canvas.formatRate(canvas.groupTotal(canvas.hoverSample, [
                                { key: "tcpSent" }, { key: "fastSyncUdpSent" }, { key: "quickCloneSent" }
                            ]))
                            + " | TCP " + canvas.formatRate(canvas.componentRate(canvas.hoverSample, "tcpSent"))
                            + " | FS UDP " + canvas.formatRate(canvas.componentRate(canvas.hoverSample, "fastSyncUdpSent"))
                            + " | QC UDP " + canvas.formatRate(canvas.componentRate(canvas.hoverSample, "quickCloneSent")))
                         : (canvas.formatSampleTime(canvas.hoverSample)
                            + "\nRec'd total " + canvas.formatRate(canvas.hoverSample.received)
                            + "\nSent total " + canvas.formatRate(canvas.hoverSample.sent)))
                      : ""
            }
        }
    }

    onDetailsModeChanged: canvas.requestPaint()
    onSamplesChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onWindowStartChanged: canvas.requestPaint()
    onWindowEndChanged: canvas.requestPaint()
}
