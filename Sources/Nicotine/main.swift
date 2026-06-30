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

        NSGraphicsContext.current?.imageInterpolation = .high

        let emberCenter = NSPoint(x: 3.7, y: 7.9)

        for radius in stride(from: 6.2, through: 2.2, by: -0.8) {
            let alpha = CGFloat(0.08 + (6.2 - radius) * 0.04)
            NSColor(calibratedRed: 1.0, green: 0.08, blue: 0.02, alpha: alpha).setFill()
            NSBezierPath(
                ovalIn: NSRect(
                    x: emberCenter.x - radius,
                    y: emberCenter.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
            ).fill()
        }

        let body = NSBezierPath(roundedRect: NSRect(x: 3.7, y: 5.5, width: 15.4, height: 5.1), xRadius: 1.25, yRadius: 1.25)
        NSColor(calibratedWhite: 0.98, alpha: 1.0).setFill()
        body.fill()

        NSColor(calibratedWhite: 0.05, alpha: 0.55).setStroke()
        body.lineWidth = 0.55
        body.stroke()

        let filter = NSBezierPath(roundedRect: NSRect(x: 15.2, y: 5.5, width: 4.7, height: 5.1), xRadius: 1.1, yRadius: 1.1)
        NSColor(calibratedRed: 0.74, green: 0.52, blue: 0.31, alpha: 1.0).setFill()
        filter.fill()

        NSColor(calibratedWhite: 1.0, alpha: 0.7).setStroke()
        let bodyHighlight = NSBezierPath()
        bodyHighlight.lineWidth = 0.65
        bodyHighlight.move(to: NSPoint(x: 5.9, y: 9.2))
        bodyHighlight.line(to: NSPoint(x: 14.2, y: 9.2))
        bodyHighlight.stroke()

        NSColor(calibratedRed: 1.0, green: 0.03, blue: 0.0, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: NSRect(x: emberCenter.x - 1.9, y: emberCenter.y - 1.9, width: 3.8, height: 3.8)).fill()

        NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.16, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: NSRect(x: emberCenter.x - 0.85, y: emberCenter.y - 0.85, width: 1.7, height: 1.7)).fill()

        NSColor(calibratedWhite: 0.82, alpha: 0.68).setStroke()
        let smoke = NSBezierPath()
        smoke.lineWidth = 1.2
        smoke.move(to: NSPoint(x: 3.8, y: 10.7))
        smoke.curve(
            to: NSPoint(x: 5.9, y: 19.1),
            controlPoint1: NSPoint(x: 1.5, y: 13.0),
            controlPoint2: NSPoint(x: 8.7, y: 15.1)
        )
        smoke.stroke()

        NSColor(calibratedWhite: 0.78, alpha: 0.48).setStroke()
        let secondSmoke = NSBezierPath()
        secondSmoke.lineWidth = 1.0
        secondSmoke.move(to: NSPoint(x: 8.0, y: 10.6))
        secondSmoke.curve(
            to: NSPoint(x: 9.8, y: 18.0),
            controlPoint1: NSPoint(x: 11.3, y: 12.8),
            controlPoint2: NSPoint(x: 6.6, y: 15.2)
        )
        secondSmoke.stroke()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

}
