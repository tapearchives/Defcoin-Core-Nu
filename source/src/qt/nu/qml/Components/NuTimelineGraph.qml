import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Theme"

Item {
    id: root
    implicitHeight: 360

    property color receivedColor: NuTokens.dataReceived
    property color sentColor: NuTokens.dataSent
    property color tcpReceivedColor: "#2fb8a6"
    property color tcpSentColor: "#4f9cff"
    property color udpReceivedColor: "#8bd450"
    property color udpSentColor: "#8b7cf6"
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

        function formatRate(value) {
            value = Math.max(0, Number(value) || 0)
            if (value >= 1024 * 1024) return (value / (1024 * 1024)).toFixed(2) + " MB/s"
            if (value >= 1024) return (value / 1024).toFixed(1) + " KB/s"
            return Math.round(value) + " B/s"
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

            let firstSecond = visible[0].seconds
            let lastSecond = visible[visible.length - 1].seconds
            let span = Math.max(1, lastSecond - firstSecond)
            let maxValue = 1
            let peakReceived = visible[0]
            let peakSent = visible[0]
            for (let i = 0; i < visible.length; ++i) {
                maxValue = Math.max(maxValue,
                                    Math.max(0, Number(visible[i].received) || 0),
                                    Math.max(0, Number(visible[i].sent) || 0),
                                    Math.max(0, Number(visible[i].tcpReceived) || 0),
                                    Math.max(0, Number(visible[i].tcpSent) || 0),
                                    Math.max(0, Number(visible[i].udpReceived) || 0),
                                    Math.max(0, Number(visible[i].udpSent) || 0))
                if (Math.max(0, Number(visible[i].received) || 0) > Math.max(0, Number(peakReceived.received) || 0)) peakReceived = visible[i]
                if (Math.max(0, Number(visible[i].sent) || 0) > Math.max(0, Number(peakSent.sent) || 0)) peakSent = visible[i]
            }

            const plotTop = 8
            const plotBottom = height - 18

            function safeRate(value) {
                const n = Number(value)
                return isNaN(n) ? 0 : Math.max(0, n)
            }
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

            drawLine("tcpReceived", root.tcpReceivedColor, 1.5, [8, 5], 0.82)
            drawLine("tcpSent", root.tcpSentColor, 1.5, [8, 5], 0.82)
            drawLine("udpReceived", root.udpReceivedColor, 1.7, [2, 4], 0.88)
            drawLine("udpSent", root.udpSentColor, 1.7, [2, 4], 0.88)
            drawLine("received", root.receivedColor, 2.5, [], 1.0)
            drawLine("sent", root.sentColor, 2.5, [], 1.0)

            ctx.fillStyle = NuTokens.textSecondary
            ctx.font = "13px sans-serif"
            const receivedLabelY = Math.max(24, Math.min(height - 48, yFor(peakReceived.received) - 10))
            const sentLabelY = Math.max(receivedLabelY + 18, Math.min(height - 24, yFor(peakSent.sent) + 20))
            ctx.fillText("Peak rec'd " + formatRate(peakReceived.received), Math.min(width - 160, xFor(peakReceived) + 8), receivedLabelY)
            ctx.fillText("Peak sent " + formatRate(peakSent.sent), Math.min(width - 150, xFor(peakSent) + 8), sentLabelY)

            const legendX = Math.max(12, width - 410)
            function legendLine(x, y, color, dashPattern) {
                ctx.save()
                ctx.strokeStyle = color
                ctx.lineWidth = 3
                if (ctx.setLineDash) ctx.setLineDash(dashPattern)
                ctx.beginPath()
                ctx.moveTo(x, y)
                ctx.lineTo(x + 28, y)
                ctx.stroke()
                if (ctx.setLineDash) ctx.setLineDash([])
                ctx.restore()
            }
            legendLine(legendX, 18, root.receivedColor, [])
            legendLine(legendX, 38, root.sentColor, [])
            legendLine(legendX + 132, 18, root.tcpReceivedColor, [8, 5])
            legendLine(legendX + 132, 38, root.tcpSentColor, [8, 5])
            legendLine(legendX + 250, 18, root.udpReceivedColor, [2, 4])
            legendLine(legendX + 250, 38, root.udpSentColor, [2, 4])
            ctx.fillStyle = NuTokens.textPrimary
            ctx.font = "13px sans-serif"
            ctx.fillText("Rec'd total", legendX + 34, 22)
            ctx.fillText("Sent total", legendX + 34, 42)
            ctx.fillText("Rec'd TCP", legendX + 166, 22)
            ctx.fillText("Sent TCP", legendX + 166, 42)
            ctx.fillText("Rec'd UDP", legendX + 284, 22)
            ctx.fillText("Sent UDP", legendX + 284, 42)
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
                      ? (canvas.formatSampleTime(canvas.hoverSample)
                         + "\nRec'd total " + canvas.formatRate(canvas.hoverSample.received)
                         + " | TCP " + canvas.formatRate(canvas.hoverSample.tcpReceived)
                         + " | UDP " + canvas.formatRate(canvas.hoverSample.udpReceived)
                         + "\nSent total " + canvas.formatRate(canvas.hoverSample.sent)
                         + " | TCP " + canvas.formatRate(canvas.hoverSample.tcpSent)
                         + " | UDP " + canvas.formatRate(canvas.hoverSample.udpSent))
                      : ""
            }
        }
    }

    onSamplesChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onWindowStartChanged: canvas.requestPaint()
    onWindowEndChanged: canvas.requestPaint()
}
