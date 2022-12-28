import AppKit
import SwiftUI

@available(macOS 10.15, *)
class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(0)
    }
}

@available(macOS 10.15, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow()
    let windowDelegate = WindowDelegate()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        appMenu.submenu?.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let mainMenu = NSMenu(title: "The app")
        mainMenu.addItem(appMenu)
        NSApplication.shared.mainMenu = mainMenu

        let size = CGSize(width: 800, height: 800)
        window.setContentSize(size)
        window.styleMask = [.closable, .miniaturizable, .resizable, .titled]
        window.delegate = windowDelegate
        window.title = "The app"

        let view = NSHostingView(rootView: ContentView())
        view.frame = CGRect(origin: .zero, size: size)
        view.autoresizingMask = [.height, .width]
        window.contentView!.addSubview(view)
        window.center()
        window.makeKeyAndOrderFront(window)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
