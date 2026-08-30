// tui2notes menu-bar agent
//
// Watches the clipboard. When a copy lands that looks like a terminal-drawn
// table, it re-writes the clipboard with BOTH a rich-text flavour (so Notes,
// Pages and Mail paste a native table) and the original plain text (so the
// terminal still pastes what you copied).
//
// No Accessibility permission: nothing is typed. No Automation permission:
// no app is scripted. It only reads and writes the pasteboard.

import Cocoa

/// Diagnostics on stderr when TUI2NOTES_DEBUG is set.
func dbg(_ msg: String) {
    guard ProcessInfo.processInfo.environment["TUI2NOTES_DEBUG"] != nil else { return }
    FileHandle.standardError.write(Data("[tui2notes] \(msg)\n".utf8))
}

final class Agent: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var lastCount = NSPasteboard.general.changeCount
    private var enabled = true
    private var converted = 0
    private let cli: String

    override init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = ["\(home)/.local/bin/tui2notes",
                          "/usr/local/bin/tui2notes",
                          "/opt/homebrew/bin/tui2notes"]
        cli = candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
            ?? candidates[0]
        super.init()
    }

    // MARK: - lifecycle

    func applicationDidFinishLaunching(_: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setIcon("tablecells")
        rebuildMenu()
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.tick()
        }
        dbg("started; cli=\(cli) exists=\(FileManager.default.isExecutableFile(atPath: cli))")
    }

    private func setIcon(_ name: String) {
        statusItem.button?.image = NSImage(systemSymbolName: name,
                                           accessibilityDescription: "tui2notes")
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Convert tables on copy",
                                action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.state = enabled ? .on : .off
        toggle.target = self
        menu.addItem(toggle)

        let now = NSMenuItem(title: "Convert clipboard now",
                             action: #selector(convertNow), keyEquivalent: "")
        now.target = self
        menu.addItem(now)

        menu.addItem(.separator())
        let count = NSMenuItem(title: converted == 1 ? "1 table converted"
                                                     : "\(converted) tables converted",
                               action: nil, keyEquivalent: "")
        count.isEnabled = false
        menu.addItem(count)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit tui2notes",
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        enabled.toggle()
        setIcon(enabled ? "tablecells" : "tablecells.badge.ellipsis")
        rebuildMenu()
    }

    @objc private func convertNow() {
        let pb = NSPasteboard.general
        guard let s = pb.string(forType: .string) else { return }
        convert(s)
    }

    // MARK: - clipboard watch

    private func tick() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastCount else { return }
        lastCount = pb.changeCount
        dbg("clipboard changed; types=\(pb.types?.map(\.rawValue) ?? [])")
        guard enabled else { return }
        // Already rich text (copied out of a document) - leave it alone.
        if pb.types?.contains(.rtf) == true { return }
        guard let s = pb.string(forType: .string) else { dbg("no string flavour"); return }
        guard looksLikeTable(s) else { dbg("not a table"); return }
        convert(s)
    }

    private func looksLikeTable(_ s: String) -> Bool {
        if s.contains("│") || s.contains("┃") {
            return s.contains("─") || s.contains("━")
        }
        for line in s.split(separator: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("|"), t.hasSuffix("|"), t.count > 2 else { continue }
            let body = t.dropFirst().dropLast()
            if body.contains("-"), body.allSatisfy({ "-: |".contains($0) }) { return true }
        }
        return false
    }

    // MARK: - conversion

    private func convert(_ text: String) {
        guard let html = run(cli, ["--html"], input: Data(text.utf8)), !html.isEmpty,
              let rtf = run("/usr/bin/textutil",
                            ["-stdin", "-format", "html", "-convert", "rtf", "-stdout"],
                            input: html), !rtf.isEmpty
        else { dbg("conversion failed"); flash("exclamationmark.triangle"); return }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.declareTypes([.rtf, .string], owner: nil)
        pb.setData(rtf, forType: .rtf)
        pb.setString(text, forType: .string)   // keep the original for plain-text targets
        lastCount = pb.changeCount
        dbg("converted, rtf bytes=\(rtf.count)")
        converted += 1
        rebuildMenu()
        flash("checkmark.circle.fill")
    }

    private func flash(_ symbol: String) {
        setIcon(symbol)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.setIcon(self.enabled ? "tablecells" : "tablecells.badge.ellipsis")
        }
    }

    private func run(_ path: String, _ args: [String], input: Data) -> Data? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
        p.standardInput = stdin; p.standardOutput = stdout; p.standardError = stderr
        do { try p.run() } catch { return nil }
        stdin.fileHandleForWriting.write(input)
        stdin.fileHandleForWriting.closeFile()
        let out = stdout.fileHandleForReading.readDataToEndOfFile()
        _ = stderr.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return p.terminationStatus == 0 ? out : nil
    }
}

// One menu-bar icon only: launchd and a manual launch must not both run.
if let id = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
    exit(0)
}

let app = NSApplication.shared
let agent = Agent()
app.delegate = agent
app.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
app.run()
