import AppKit
import CoreGraphics
import Foundation
import ImageIO
import Vision

struct ToolError: Error, CustomStringConvertible {
    let description: String
}

struct Config {
    var timeoutSeconds: Double = 8
    var intervalSeconds: Double = 1
    var buttonText = ""
    var contextText = ""
    var dryRun = false
    var requireContext = true
    var saveLastScreenshot: URL?
}

struct ScreenShot {
    let image: CGImage
    let displayBounds: CGRect
    let displayIndex: Int
    let fileURL: URL
    let temporary: Bool
}

struct Candidate {
    let text: String
    let confidence: Float
    let point: CGPoint
    let displayIndex: Int
}

struct ScanResult {
    let contextFound: Bool
    let candidate: Candidate?
    let observedTextCount: Int
}

func usage() -> String {
    """
    Usage:
      macos_click_visible_button --button TEXT --context TEXT [--timeout SECONDS] [--interval SECONDS]

    Screenshots every active display, uses Vision OCR, and clicks an exact visible
    button only when the required context text is also visible. This is intended
    for macOS system dialogs that are visible but not exposed reliably through
    Accessibility, such as crash reporter alerts.

    Options:
      --button TEXT                  Exact button text to click, for example Ignore.
      --context TEXT                 Required nearby/window text, for example quit unexpectedly.
      --timeout, --wait SECONDS      Total time to scan. Default: 8.
      --interval SECONDS             Scan interval. Default: 1.
      --save-last-screenshot PATH    Keep the latest screenshot for debugging.
      --no-context-check             Allow exact button click without context.
      --dry-run                      Report the target without clicking.
      -h, --help                     Show this help.
    """
}

func parsePositiveNumber(_ value: String, name: String, allowZero: Bool = false) throws -> Double {
    guard let parsed = Double(value), parsed.isFinite, parsed >= (allowZero ? 0 : Double.ulpOfOne) else {
        throw ToolError(description: "\(name) must be \(allowZero ? ">= 0" : "> 0") seconds.")
    }
    return parsed
}

func parseArguments(_ args: [String]) throws -> Config {
    var config = Config()
    var index = 0

    func requireValue(after option: String) throws -> String {
        let nextIndex = index + 1
        guard nextIndex < args.count else {
            throw ToolError(description: "\(option) requires a value.")
        }
        index = nextIndex
        return args[index]
    }

    while index < args.count {
        let arg = args[index]
        switch arg {
        case "-h", "--help":
            print(usage())
            exit(0)
        case "--button":
            config.buttonText = try requireValue(after: arg)
        case "--context":
            config.contextText = try requireValue(after: arg)
        case "--timeout", "--wait":
            config.timeoutSeconds = try parsePositiveNumber(try requireValue(after: arg), name: arg, allowZero: true)
        case "--interval":
            config.intervalSeconds = try parsePositiveNumber(try requireValue(after: arg), name: arg)
        case "--save-last-screenshot":
            config.saveLastScreenshot = URL(fileURLWithPath: try requireValue(after: arg))
        case "--no-context-check":
            config.requireContext = false
        case "--dry-run":
            config.dryRun = true
        default:
            throw ToolError(description: "Unknown option: \(arg)")
        }
        index += 1
    }

    guard !config.buttonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw ToolError(description: "--button is required.")
    }
    if config.requireContext && config.contextText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw ToolError(description: "--context is required unless --no-context-check is used.")
    }
    return config
}

func emitJSON(_ object: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
       let text = String(data: data, encoding: .utf8) {
        print(text)
    } else {
        print("{\"ok\":false,\"status\":\"json_encoding_failed\"}")
    }
}

func normalizedWords(_ text: String) -> String {
    let lowered = text
        .replacingOccurrences(of: "\u{2019}", with: "'")
        .replacingOccurrences(of: "\u{2018}", with: "'")
        .lowercased()
    let allowed = CharacterSet.alphanumerics.union(.whitespaces)
    let scalars = lowered.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " }
    return String(scalars)
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
}

func normalizedButtonText(_ text: String) -> String {
    text
        .replacingOccurrences(of: "\u{2019}", with: "'")
        .replacingOccurrences(of: "\u{2018}", with: "'")
        .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters).union(.symbols))
        .lowercased()
}

func displayList() throws -> [CGDirectDisplayID] {
    var count: UInt32 = 0
    let countError = CGGetActiveDisplayList(0, nil, &count)
    if countError == .success, count == 0 {
        let mainDisplay = CGMainDisplayID()
        if mainDisplay != 0 {
            return [mainDisplay]
        }
    }
    guard countError == .success, count > 0 else {
        throw ToolError(description: "Could not list active displays.")
    }

    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    let listError = CGGetActiveDisplayList(count, &displays, &count)
    guard listError == .success else {
        throw ToolError(description: "Could not read active display IDs.")
    }
    return displays
}

func screenshotURL(base: URL?, displayIndex: Int, displayCount: Int) throws -> (URL, Bool) {
    if let base {
        let manager = FileManager.default
        let directory = base.deletingLastPathComponent()
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        if displayCount == 1 {
            return (base, false)
        }
        let ext = base.pathExtension.isEmpty ? "png" : base.pathExtension
        let stem = base.deletingPathExtension().lastPathComponent
        let indexed = directory.appendingPathComponent("\(stem)-display\(displayIndex)").appendingPathExtension(ext)
        return (indexed, false)
    }

    let path = NSTemporaryDirectory() + "defcoin-nu-visible-button-\(UUID().uuidString)-display\(displayIndex).png"
    return (URL(fileURLWithPath: path), true)
}

func runScreenCapture(displayIndex: Int, to fileURL: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = ["-x", "-t", "png", "-D", "\(displayIndex)", fileURL.path]
    let stderr = Pipe()
    process.standardError = stderr

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        let data = stderr.fileHandleForReading.readDataToEndOfFile()
        let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        throw ToolError(description: "screencapture failed for display \(displayIndex): \(message ?? "exit \(process.terminationStatus)")")
    }
}

func loadImage(_ fileURL: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw ToolError(description: "Could not load screenshot image: \(fileURL.path)")
    }
    return image
}

func captureScreens(config: Config) throws -> [ScreenShot] {
    let displays = try displayList()
    var shots: [ScreenShot] = []

    for (offset, display) in displays.enumerated() {
        let displayIndex = offset + 1
        let (url, temporary) = try screenshotURL(base: config.saveLastScreenshot, displayIndex: displayIndex, displayCount: displays.count)
        try runScreenCapture(displayIndex: displayIndex, to: url)
        shots.append(ScreenShot(
            image: try loadImage(url),
            displayBounds: CGDisplayBounds(display),
            displayIndex: displayIndex,
            fileURL: url,
            temporary: temporary
        ))
    }

    return shots
}

func cleanup(_ shots: [ScreenShot]) {
    for shot in shots where shot.temporary {
        try? FileManager.default.removeItem(at: shot.fileURL)
    }
}

func screenPoint(for observation: VNRecognizedTextObservation, shot: ScreenShot) -> CGPoint {
    let imageWidth = CGFloat(shot.image.width)
    let imageHeight = CGFloat(shot.image.height)
    let scaleX = imageWidth / max(shot.displayBounds.width, 1)
    let scaleY = imageHeight / max(shot.displayBounds.height, 1)
    let centerPixelX = observation.boundingBox.midX * imageWidth
    let centerPixelYFromTop = imageHeight - (observation.boundingBox.midY * imageHeight)

    return CGPoint(
        x: shot.displayBounds.minX + (centerPixelX / scaleX),
        y: shot.displayBounds.minY + (centerPixelYFromTop / scaleY)
    )
}

func scan(_ shots: [ScreenShot], config: Config) throws -> ScanResult {
    var allTexts: [String] = []
    var candidates: [Candidate] = []
    let targetButton = normalizedButtonText(config.buttonText)
    let targetContext = normalizedWords(config.contextText)

    for shot in shots {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: shot.image, options: [:])
        try handler.perform([request])

        for observation in request.results ?? [] {
            guard let recognized = observation.topCandidates(3).first else {
                continue
            }
            let text = recognized.string
            allTexts.append(text)
            if normalizedButtonText(text) == targetButton {
                candidates.append(Candidate(
                    text: text,
                    confidence: recognized.confidence,
                    point: screenPoint(for: observation, shot: shot),
                    displayIndex: shot.displayIndex
                ))
            }
        }
    }

    let normalizedAllText = normalizedWords(allTexts.joined(separator: " "))
    let contextFound = !config.requireContext || normalizedAllText.contains(targetContext)
    let best = contextFound
        ? candidates.sorted { left, right in
            if left.displayIndex != right.displayIndex {
                return left.displayIndex < right.displayIndex
            }
            if abs(left.point.y - right.point.y) > 1 {
                return left.point.y < right.point.y
            }
            return left.confidence > right.confidence
        }.first
        : nil

    return ScanResult(contextFound: contextFound, candidate: best, observedTextCount: allTexts.count)
}

func click(point: CGPoint) throws {
    guard AXIsProcessTrusted() else {
        throw ToolError(description: "Accessibility permission is required to post mouse clicks.")
    }

    let source = CGEventSource(stateID: .hidSystemState)
    guard let move = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left),
          let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
          let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
        throw ToolError(description: "Could not create mouse click events.")
    }

    move.post(tap: .cghidEventTap)
    usleep(70_000)
    down.post(tap: .cghidEventTap)
    usleep(90_000)
    up.post(tap: .cghidEventTap)
}

func sleepUntilNextAttempt(interval: Double, deadline: Date) {
    let remaining = deadline.timeIntervalSinceNow
    if remaining <= 0 {
        return
    }
    usleep(useconds_t(min(interval, remaining) * 1_000_000))
}

func main() -> Int32 {
    let started = Date()
    let config: Config
    do {
        config = try parseArguments(Array(CommandLine.arguments.dropFirst()))
    } catch {
        fputs("\(error)\n\n\(usage())\n", stderr)
        return 2
    }

    guard CGPreflightScreenCaptureAccess() else {
        emitJSON([
            "ok": false,
            "status": "screen_recording_permission_missing",
            "message": "Grant Screen Recording permission to the app or terminal running this utility."
        ])
        return 4
    }

    guard AXIsProcessTrusted() || config.dryRun else {
        emitJSON([
            "ok": false,
            "status": "accessibility_permission_missing",
            "message": "Grant Accessibility permission to the app or terminal running this utility."
        ])
        return 4
    }

    let deadline = started.addingTimeInterval(config.timeoutSeconds)
    var attempts = 0
    var lastObservedTextCount = 0
    var lastContext = false
    var lastError: String?

    repeat {
        attempts += 1
        do {
            let shots = try captureScreens(config: config)
            defer { cleanup(shots) }
            let result = try scan(shots, config: config)
            lastObservedTextCount = result.observedTextCount
            lastContext = result.contextFound

            if let candidate = result.candidate {
                if !config.dryRun {
                    try click(point: candidate.point)
                    usleep(600_000)
                }
                emitJSON([
                    "ok": true,
                    "status": config.dryRun ? "found_dry_run" : "clicked",
                    "button": config.buttonText,
                    "contextFound": result.contextFound,
                    "attempts": attempts,
                    "elapsedSeconds": Date().timeIntervalSince(started),
                    "display": candidate.displayIndex,
                    "x": Double(candidate.point.x),
                    "y": Double(candidate.point.y),
                    "confidence": Double(candidate.confidence),
                    "text": candidate.text
                ])
                return 0
            }
        } catch {
            lastError = String(describing: error)
        }

        sleepUntilNextAttempt(interval: config.intervalSeconds, deadline: deadline)
    } while Date() < deadline

    emitJSON([
        "ok": false,
        "status": lastContext ? "button_not_found" : "context_not_found",
        "button": config.buttonText,
        "contextFound": lastContext,
        "attempts": attempts,
        "elapsedSeconds": Date().timeIntervalSince(started),
        "observedTextCount": lastObservedTextCount,
        "lastError": lastError ?? NSNull()
    ])
    return 1
}

exit(main())
