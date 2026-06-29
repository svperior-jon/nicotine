import AppKit
import IOKit.pwr_mgt
import ServiceManagement

@main
final class NicotineApp: NSObject, NSApplicationDelegate {
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
        configureMenuBarItem()
        configureMenu()
        startKeepingDisplayAwake()
        enableLaunchAtLogin()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopKeepingDisplayAwake()
    }

    private func configureMenuBarItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = nil
        button.title = "🚬"
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
            refreshMenu()
            return
        }

        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("Nicotine could not enable launch at login: \(error.localizedDescription)")
        }

        refreshMenu()
    }

    private func disableLaunchAtLogin() {
        guard SMAppService.mainApp.status == .enabled else {
            refreshMenu()
            return
        }

        do {
            try SMAppService.mainApp.unregister()
        } catch {
            NSLog("Nicotine could not disable launch at login: \(error.localizedDescription)")
        }

        refreshMenu()
    }

}
