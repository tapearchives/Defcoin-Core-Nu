import ApplicationServices
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import Vision

struct ToolError: Error, CustomStringConvertible {
    let description: String
}

struct Config {
    var timeoutSeconds: Double = 30
    var intervalSeconds: Double = 6
    var requireLocalNetworkContext = true
    var dryRun = false
    var allowOcrFallback = false
    var saveLastScreenshot: URL?
    var targetPid: pid_t?
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
    let boundingBox: CGRect
}

struct TextHit {
    let text: String
    let point: CGPoint
    let displayIndex: Int
}

struct ScanResult {
    let foundContext: Bool
    let candidate: Candidate?
    let observedTexts: [String]
}

struct AccessibilityPrompt {
    let appName: String
    let pid: pid_t
    let button: AXUIElement
}

func usage() -> String {
    """
    Usage:
      macos_click_lan_allow [--timeout SECONDS] [--interval SECONDS] [--target-pid PID] [--save-last-screenshot PATH]
      macos_click_lan_allow SECONDS

    Screenshots every active display, uses Vision OCR to find the macOS Local
    Network permission dialog, and clicks the exact Allow button. The screenshot
    is repeated every 6 seconds by default until the timeout expires.

    Options:
      --timeout, --wait SECONDS       Total time to look for Allow. Default: 30.
      --interval SECONDS             Screenshot interval. Default: 6.
      --target-pid PID               Bring this Nu process to the foreground before each screenshot.
      --save-last-screenshot PATH    Keep the latest screenshot for debugging.
      --ocr-fallback                 Use whole-screen OCR if Accessibility cannot find the native prompt.
      --no-context-check             Click an exact Allow OCR match without requiring Local Network text.
      --dry-run                      Report the target without clicking.
      -h, --help                     Show this help.

    Exit codes:
      0  Allow was found and clicked.
      1  Allow was not found before timeout.
      2  Invalid arguments.
      3  Screenshot or OCR failed.
      4  Required macOS Screen Recording or Accessibility permission is missing.
    """
}

func parsePositiveNumber(_ value: String, name: String, allowZero: Bool = false) throws -> Double {
    guard let parsed = Double(value), parsed.isFinite, parsed >= (allowZero ? 0 : Double.ulpOfOne) else {
        throw ToolError(description: "\(name) must be \(allowZero ? ">= 0" : "> 0") seconds.")
    }
    return parsed
}

func parsePid(_ value: String, name: String) throws -> pid_t {
    guard let parsed = Int32(value), parsed > 0 else {
        throw ToolError(description: "\(name) must be a positive process id.")
    }
    return parsed
}

func parseArguments(_ args: [String]) throws -> Config {
    var config = Config()
    var index = 0
    var positionalTimeoutUsed = false

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
        case "--timeout", "--wait", "--wait-seconds":
            let value = try requireValue(after: arg)
            config.timeoutSeconds = try parsePositiveNumber(value, name: arg, allowZero: true)
        case "--interval":
            let value = try requireValue(after: arg)
            config.intervalSeconds = try parsePositiveNumber(value, name: arg)
        case "--target-pid":
            let value = try requireValue(after: arg)
            config.targetPid = try parsePid(value, name: arg)
        case "--save-last-screenshot":
            let value = try requireValue(after: arg)
            config.saveLastScreenshot = URL(fileURLWithPath: value)
        case "--ocr-fallback":
            config.allowOcrFallback = true
        case "--no-context-check":
            config.requireLocalNetworkContext = false
        case "--dry-run":
            config.dryRun = true
        default:
            if !arg.hasPrefix("-"), !positionalTimeoutUsed {
                config.timeoutSeconds = try parsePositiveNumber(arg, name: "timeout", allowZero: true)
                positionalTimeoutUsed = true
            } else {
                throw ToolError(description: "Unknown option: \(arg)")
            }
        }
        index += 1
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

    let path = NSTemporaryDirectory() + "defcoin-nu-macos-lan-allow-\(UUID().uuidString)-display\(displayIndex).png"
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
    try foregroundDefcoinNu(targetPid: config.targetPid)

    let displays = try displayList()
    var shots: [ScreenShot] = []

    for (offset, display) in displays.enumerated() {
        let displayIndex = offset + 1
        let (url, temporary) = try screenshotURL(base: config.saveLastScreenshot, displayIndex: displayIndex, displayCount: displays.count)
        try runScreenCapture(displayIndex: displayIndex, to: url)
        let image = try loadImage(url)
        shots.append(ScreenShot(image: image, displayBounds: CGDisplayBounds(display), displayIndex: displayIndex, fileURL: url, temporary: temporary))
    }

    return shots
}

func foregroundDefcoinNu(targetPid: pid_t?) throws {
    let running = NSWorkspace.shared.runningApplications
    if let targetPid, let app = running.first(where: { $0.processIdentifier == targetPid }) {
        activate(app)
        return
    }

    if let targetPid {
        throw ToolError(description: "Target Nu process \(targetPid) is not running.")
    }

    let candidates = running.filter { app in
        let haystack = [
            app.localizedName ?? "",
            app.bundleIdentifier ?? "",
            app.executableURL?.lastPathComponent ?? "",
            app.bundleURL?.lastPathComponent ?? ""
        ].joined(separator: " ")

        return haystack.contains("DefcoinCoreNu")
            || haystack.contains("Defcoin Core Nu")
            || haystack.contains("DefcoinCoreNuLion")
            || haystack.contains("org.defcoincore")
    }

    guard let app = candidates.sorted(by: { left, right in
        if left.isActive != right.isActive {
            return left.isActive
        }
        return left.processIdentifier > right.processIdentifier
    }).first else {
        return
    }

    activate(app)
}

func activate(_ app: NSRunningApplication) {
    if #available(macOS 14.0, *) {
        app.activate()
    } else {
        _ = app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }
    usleep(250_000)
}

func axString(_ element: AXUIElement, _ attribute: CFString) -> String? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
        return nil
    }
    return value as? String
}

func axArray(_ element: AXUIElement, _ attribute: CFString) -> [AXUIElement] {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
        return []
    }
    return value as? [AXUIElement] ?? []
}

func axElementText(_ element: AXUIElement) -> String {
    [
        axString(element, kAXTitleAttribute as CFString),
        axString(element, kAXValueAttribute as CFString),
        axString(element, kAXDescriptionAttribute as CFString),
        axString(element, kAXHelpAttribute as CFString)
    ].compactMap { $0 }.joined(separator: " ")
}

func axContainsLocalNetworkText(_ element: AXUIElement, depth: Int = 0, nodeBudget: inout Int) -> Bool {
    guard depth <= 7, nodeBudget > 0 else {
        return false
    }
    nodeBudget -= 1

    if textHasLocalNetworkContext(axElementText(element)) {
        return true
    }

    for child in axArray(element, kAXChildrenAttribute as CFString) {
        if axContainsLocalNetworkText(child, depth: depth + 1, nodeBudget: &nodeBudget) {
            return true
        }
    }
    return false
}

func axFindAllowButton(_ element: AXUIElement, depth: Int = 0, nodeBudget: inout Int) -> AXUIElement? {
    guard depth <= 7, nodeBudget > 0 else {
        return nil
    }
    nodeBudget -= 1

    let title = normalizedButtonText(axElementText(element))
    if title == "allow" {
        return element
    }

    for child in axArray(element, kAXChildrenAttribute as CFString) {
        if let found = axFindAllowButton(child, depth: depth + 1, nodeBudget: &nodeBudget) {
            return found
        }
    }
    return nil
}

func accessibilitySearchApps(targetPid: pid_t?) -> [NSRunningApplication] {
    let running = NSWorkspace.shared.runningApplications
    var ordered: [NSRunningApplication] = []

    if let targetPid, let target = running.first(where: { $0.processIdentifier == targetPid }) {
        ordered.append(target)
    }

    let preferredNames = ["CoreServicesUIAgent", "UserNotificationCenter", "osascript"]
    ordered.append(contentsOf: running.filter { app in
        let haystack = [
            app.localizedName ?? "",
            app.bundleIdentifier ?? "",
            app.executableURL?.lastPathComponent ?? ""
        ].joined(separator: " ")
        return preferredNames.contains { haystack.contains($0) }
    })

    ordered.append(contentsOf: running.filter { $0.isActive })
    ordered.append(contentsOf: running)

    var seen = Set<pid_t>()
    return ordered.filter { app in
        if seen.contains(app.processIdentifier) {
            return false
        }
        seen.insert(app.processIdentifier)
        return true
    }
}

func findAccessibilityPrompt(targetPid: pid_t?) -> AccessibilityPrompt? {
    for app in accessibilitySearchApps(targetPid: targetPid) {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        let windows = axArray(appElement, kAXWindowsAttribute as CFString)
        for window in windows {
            var contextBudget = 250
            guard axContainsLocalNetworkText(window, nodeBudget: &contextBudget) else {
                continue
            }
            var buttonBudget = 250
            guard let button = axFindAllowButton(window, nodeBudget: &buttonBudget) else {
                continue
            }
            return AccessibilityPrompt(
                appName: app.localizedName ?? app.executableURL?.lastPathComponent ?? "unknown",
                pid: app.processIdentifier,
                button: button
            )
        }
    }
    return nil
}

func pressAccessibilityAllow(targetPid: pid_t?) -> AccessibilityPrompt? {
    guard let prompt = findAccessibilityPrompt(targetPid: targetPid) else {
        return nil
    }
    guard AXUIElementPerformAction(prompt.button, kAXPressAction as CFString) == .success else {
        return nil
    }
    usleep(650_000)
    return prompt
}

func cleanup(_ shots: [ScreenShot]) {
    for shot in shots where shot.temporary {
        try? FileManager.default.removeItem(at: shot.fileURL)
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

func hasLocalNetworkContext(_ texts: [String]) -> Bool {
    let joined = normalizedWords(texts.joined(separator: " "))
    let compact = joined.replacingOccurrences(of: " ", with: "")
    let hasLocalNetwork = joined.contains("local network")
        || joined.contains("local networks")
        || compact.contains("localnetwork")
        || compact.contains("localnetworks")
    let hasSystemPromptText = joined.contains("find devices")
        || joined.contains("find devices on local networks")
        || joined.contains("devices on your networks")
        || joined.contains("discover connect to and collect data from devices")
        || joined.contains("allow defcoincorenu")
        || joined.contains("allow defcoin core nu")
    return hasLocalNetwork && hasSystemPromptText
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

func scan(_ shots: [ScreenShot], requireContext: Bool) throws -> ScanResult {
    var candidates: [Candidate] = []
    var contextHits: [TextHit] = []
    var texts: [String] = []

    for shot in shots {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: shot.image, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        for observation in observations {
            guard let recognized = observation.topCandidates(3).first else {
                continue
            }
            let text = recognized.string
            texts.append(text)
            let point = screenPoint(for: observation, shot: shot)
            let contextText = normalizedWords(text)

            if textHasLocalNetworkContext(text) {
                contextHits.append(TextHit(text: text, point: point, displayIndex: shot.displayIndex))
            }

            let normalized = normalizedButtonText(text)
            if normalized == "allow", !contextText.contains("dont"), !contextText.contains("don t") {
                candidates.append(Candidate(
                    text: text,
                    confidence: recognized.confidence,
                    point: point,
                    displayIndex: shot.displayIndex,
                    boundingBox: observation.boundingBox
                ))
            }
        }
    }

    let contextFound = hasLocalNetworkContext(texts)
    let usableCandidates = candidates.filter { candidate in
        !requireContext || contextHits.contains { context in
            guard context.displayIndex == candidate.displayIndex else {
                return false
            }
            let dx = abs(candidate.point.x - context.point.x)
            let dy = candidate.point.y - context.point.y
            return dx <= 420 && dy >= 20 && dy <= 360
        }
    }

    let best = usableCandidates.sorted { left, right in
        if left.displayIndex != right.displayIndex {
            return left.displayIndex < right.displayIndex
        }
        if abs(left.point.x - right.point.x) > 1 {
            return left.point.x > right.point.x
        }
        return left.confidence > right.confidence
    }.first

    return ScanResult(foundContext: contextFound, candidate: best, observedTexts: texts)
}

func textHasLocalNetworkContext(_ text: String) -> Bool {
    let joined = normalizedWords(text)
    let compact = joined.replacingOccurrences(of: " ", with: "")
    return joined.contains("local network")
        || joined.contains("local networks")
        || joined.contains("devices on your local")
        || compact.contains("localnetwork")
        || compact.contains("localnetworks")
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

func localNetworkPromptStillVisible(config: Config) -> Bool {
    usleep(650_000)

    if findAccessibilityPrompt(targetPid: config.targetPid) == nil {
        return false
    }

    do {
        let shots = try captureScreens(config: config)
        defer { cleanup(shots) }
        let scanResult = try scan(shots, requireContext: config.requireLocalNetworkContext)
        return scanResult.foundContext && scanResult.candidate != nil
    } catch {
        // A verification capture failure should not make a posted click look successful.
        return true
    }
}

func sleepUntilNextAttempt(interval: Double, deadline: Date) {
    let remaining = deadline.timeIntervalSinceNow
    if remaining <= 0 {
        return
    }
    let delay = min(interval, remaining)
    if delay > 0 {
        usleep(useconds_t(delay * 1_000_000))
    }
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

    if let targetPid = config.targetPid,
       !NSWorkspace.shared.runningApplications.contains(where: { $0.processIdentifier == targetPid }) {
        emitJSON([
            "ok": false,
            "status": "target_process_not_running",
            "message": "Target Nu process \(targetPid) is not running."
        ])
        return 3
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
    var lastContext = false
    var lastObservedTextCount = 0
    var lastError: String?

    if let prompt = findAccessibilityPrompt(targetPid: config.targetPid) {
        if config.dryRun {
            emitJSON([
                "ok": true,
                "status": "found_accessibility_dry_run",
                "attempts": 0,
                "elapsedSeconds": Date().timeIntervalSince(started),
                "app": prompt.appName,
                "pid": prompt.pid
            ])
            return 0
        }

        if let pressed = pressAccessibilityAllow(targetPid: config.targetPid) {
            if findAccessibilityPrompt(targetPid: config.targetPid) == nil {
                emitJSON([
                    "ok": true,
                    "status": "clicked_accessibility",
                    "attempts": 0,
                    "elapsedSeconds": Date().timeIntervalSince(started),
                    "app": pressed.appName,
                    "pid": pressed.pid
                ])
                return 0
            }
            lastError = "Pressed the native Allow button, but the Local Network prompt was still visible after verification."
        } else {
            lastError = "Found a native Local Network Allow button, but AXPress did not succeed."
        }
    }

    repeat {
        attempts += 1
        if let prompt = findAccessibilityPrompt(targetPid: config.targetPid) {
            if config.dryRun {
                emitJSON([
                    "ok": true,
                    "status": "found_accessibility_dry_run",
                    "attempts": attempts,
                    "elapsedSeconds": Date().timeIntervalSince(started),
                    "app": prompt.appName,
                    "pid": prompt.pid
                ])
                return 0
            }

            if let pressed = pressAccessibilityAllow(targetPid: config.targetPid) {
                if findAccessibilityPrompt(targetPid: config.targetPid) == nil {
                    emitJSON([
                        "ok": true,
                        "status": "clicked_accessibility",
                        "attempts": attempts,
                        "elapsedSeconds": Date().timeIntervalSince(started),
                        "app": pressed.appName,
                        "pid": pressed.pid
                    ])
                    return 0
                }
                lastError = "Pressed the native Allow button, but the Local Network prompt was still visible after verification."
            } else {
                lastError = "Found a native Local Network Allow button, but AXPress did not succeed."
            }
        }

        if !config.allowOcrFallback {
            sleepUntilNextAttempt(interval: config.intervalSeconds, deadline: deadline)
            continue
        }

        do {
            let shots = try captureScreens(config: config)
            defer { cleanup(shots) }

            let scanResult = try scan(shots, requireContext: config.requireLocalNetworkContext)
            lastContext = scanResult.foundContext
            lastObservedTextCount = scanResult.observedTexts.count

                if let candidate = scanResult.candidate {
                    if !config.dryRun {
                        try click(point: candidate.point)
                        if localNetworkPromptStillVisible(config: config) {
                            lastError = "Clicked OCR target, but the Local Network prompt was still visible after verification."
                            sleepUntilNextAttempt(interval: min(1.0, config.intervalSeconds), deadline: deadline)
                            continue
                        }
                    }
                    emitJSON([
                        "ok": true,
                    "status": config.dryRun ? "found_dry_run" : "clicked",
                    "attempts": attempts,
                    "elapsedSeconds": Date().timeIntervalSince(started),
                    "display": candidate.displayIndex,
                    "x": Double(candidate.point.x),
                    "y": Double(candidate.point.y),
                    "confidence": Double(candidate.confidence),
                    "contextFound": scanResult.foundContext,
                    "text": candidate.text
                ])
                return 0
            }
        } catch {
            lastError = String(describing: error)
            sleepUntilNextAttempt(interval: min(1.0, config.intervalSeconds), deadline: deadline)
            continue
        }

        sleepUntilNextAttempt(interval: config.intervalSeconds, deadline: deadline)
    } while Date() < deadline

    if !lastContext {
        emitJSON([
            "ok": true,
            "status": "no_prompt_visible",
            "attempts": attempts,
            "elapsedSeconds": Date().timeIntervalSince(started),
            "contextFound": false,
            "observedTextCount": lastObservedTextCount,
            "message": "No Local Network Allow prompt was visible."
        ])
        return 0
    }

    emitJSON([
        "ok": false,
        "status": "not_found",
        "attempts": attempts,
        "elapsedSeconds": Date().timeIntervalSince(started),
        "contextFound": lastContext,
        "observedTextCount": lastObservedTextCount,
        "message": !config.allowOcrFallback
            ? "No native Local Network Allow prompt was found."
            : (config.requireLocalNetworkContext
            ? "No exact Allow button was found in a screenshot containing Local Network prompt text."
            : "No exact Allow button was found."),
        "lastError": lastError as Any
    ])
    return 1
}

exit(main())
