import AppKit
import IOKit.pwr_mgt
import ServiceManagement

@main
final class NicotineApp: NSObject, NSApplicationDelegate {
    private static let launchAtLoginPreferenceKey = "LaunchAtLoginPreferenceSet"

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: "", action: #selector(toggleAwake), keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

    private var assertionID = IOPMAssertionID(0)
    private var isKeepingDisplayAwake = false

    static func main() {
        let app = NSApplication.shared
        let delegate = NicotineApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()

        _ = delegate
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        migrateAutomaticLaunchAtLogin()
        configureMenuBarItem()
        configureMenu()
        startKeepingDisplayAwake()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopKeepingDisplayAwake()
    }

    private func configureMenuBarItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = Self.makeMenuBarIcon()
        button.imagePosition = .imageOnly
        button.title = ""
        button.toolTip = "Nicotine keeps the display awake"
    }

    private func configureMenu() {
        stateItem.isEnabled = false

        toggleItem.target = self
        launchAtLoginItem.target = self

        let quitItem = NSMenuItem(title: "Quit Nicotine", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApplication.shared

        menu.addItem(stateItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(toggleItem)
        menu.addItem(launchAtLoginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu
        refreshMenu()
    }

    @objc private func toggleAwake() {
        if isKeepingDisplayAwake {
            stopKeepingDisplayAwake()
        } else {
            startKeepingDisplayAwake()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        if SMAppService.mainApp.status == .enabled {
            disableLaunchAtLogin()
        } else {
            enableLaunchAtLogin()
        }
    }

    private func startKeepingDisplayAwake() {
        guard !isKeepingDisplayAwake else {
            return
        }

        let reason = "Nicotine is keeping the display awake" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )

        isKeepingDisplayAwake = result == kIOReturnSuccess
        refreshMenu()
    }

    private func stopKeepingDisplayAwake() {
        guard isKeepingDisplayAwake else {
            return
        }

        let result = IOPMAssertionRelease(assertionID)
        if result == kIOReturnSuccess {
            assertionID = IOPMAssertionID(0)
            isKeepingDisplayAwake = false
        }

        refreshMenu()
    }

    private func refreshMenu() {
        if isKeepingDisplayAwake {
            stateItem.title = "Display awake: On"
            toggleItem.title = "Pause"
        } else {
            stateItem.title = "Display awake: Off"
            toggleItem.title = "Resume"
        }

        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .on
            launchAtLoginItem.isEnabled = true
        case .requiresApproval:
            launchAtLoginItem.title = "Launch at Login (Approve in Settings)"
            launchAtLoginItem.state = .off
            launchAtLoginItem.isEnabled = true
        case .notRegistered:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
            launchAtLoginItem.isEnabled = true
        case .notFound:
            launchAtLoginItem.title = "Launch at Login (Unavailable)"
            launchAtLoginItem.state = .off
            launchAtLoginItem.isEnabled = false
        @unknown default:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
            launchAtLoginItem.isEnabled = true
        }
    }

    private func enableLaunchAtLogin() {
        guard SMAppService.mainApp.status != .enabled else {
            UserDefaults.standard.set(true, forKey: Self.launchAtLoginPreferenceKey)
            refreshMenu()
            return
        }

        do {
            try SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: Self.launchAtLoginPreferenceKey)
        } catch {
            NSLog("Nicotine could not enable launch at login: \(error.localizedDescription)")
        }

        refreshMenu()
    }

    private func disableLaunchAtLogin() {
        guard SMAppService.mainApp.status == .enabled else {
            UserDefaults.standard.set(true, forKey: Self.launchAtLoginPreferenceKey)
            refreshMenu()
            return
        }

        do {
            try SMAppService.mainApp.unregister()
            UserDefaults.standard.set(true, forKey: Self.launchAtLoginPreferenceKey)
        } catch {
            NSLog("Nicotine could not disable launch at login: \(error.localizedDescription)")
        }

        refreshMenu()
    }

    private func migrateAutomaticLaunchAtLogin() {
        guard !UserDefaults.standard.bool(forKey: Self.launchAtLoginPreferenceKey) else {
            return
        }

        if SMAppService.mainApp.status == .enabled {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                NSLog("Nicotine could not migrate launch at login: \(error.localizedDescription)")
            }
        }
    }

    private static func makeMenuBarIcon() -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()

        let emoji = "🚬" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16)
        ]

        emoji.draw(in: NSRect(x: 1, y: 1, width: 20, height: 20), withAttributes: attributes)

        let glowCenter = NSPoint(x: 16.8, y: 11.6)
        for radius in stride(from: 5.0, through: 2.0, by: -1.0) {
            let alpha = CGFloat((6.0 - radius) / 18.0)
            NSColor.systemRed.withAlphaComponent(alpha).setFill()
            NSBezierPath(
                ovalIn: NSRect(
                    x: glowCenter.x - radius,
                    y: glowCenter.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
            ).fill()
        }

        NSColor.systemOrange.setFill()
        NSBezierPath(ovalIn: NSRect(x: glowCenter.x - 1.5, y: glowCenter.y - 1.5, width: 3, height: 3)).fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

}
