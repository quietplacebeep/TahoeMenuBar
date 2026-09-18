//
//  AppDelegate.swift
//  ClearMenuBar
//

import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    private var statusItem: NSStatusItem?
    private var launchAtLoginMenuItem: NSMenuItem?
    
    private var menuBarWindowController: MenuBarWindowController?
    private var shadowWindowController: ShadowWindowController?
    
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusItem()
        setupWindows()
        refresh()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "TahoeMenuBar") {
                var config = NSImage.SymbolConfiguration(textStyle: .body, scale: .medium)
                config = config.applying(.init(pointSize: 15.0, weight: .regular))
                button.image = image.withSymbolConfiguration(config)
            } else {
                button.title = "⎕"
            }
        }
        
        let menu = NSMenu()
        menu.delegate = self
        
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshAction(_:)), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        self.launchAtLoginMenuItem = launchItem
        menu.addItem(launchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitAction(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func setupWindows() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let menuBarHeight = screen.menuBarHeight
        let screenFrame = screen.frame
        
        // Menu bar backdrop window
        let menuBarRect = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y + screenFrame.height - menuBarHeight,
            width: screenFrame.width,
            height: menuBarHeight
        )
        let menuBarWindow = MenuBarWindow(
            contentRect: menuBarRect,
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        let mbController = MenuBarWindowController(window: menuBarWindow)
        mbController.showWindow(self)
        self.menuBarWindowController = mbController
        
        // Shadow window
        let shadowHeight: CGFloat = 80.0
        let shadowRect = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y + screenFrame.height - (menuBarHeight + shadowHeight),
            width: screenFrame.width,
            height: shadowHeight
        )
        let shadowWindow = ShadowWindow(
            contentRect: shadowRect,
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        let swController = ShadowWindowController(window: shadowWindow)
        swController.showWindow(self)
        self.shadowWindowController = swController
    }
    
    public func refresh() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let menuBarHeight = screen.menuBarHeight
        let screenFrame = screen.frame
        
        // Update window positions in case screen metrics changed
        if let mbWindow = menuBarWindowController?.window {
            let menuBarRect = NSRect(
                x: screenFrame.origin.x,
                y: screenFrame.origin.y + screenFrame.height - menuBarHeight,
                width: screenFrame.width,
                height: menuBarHeight
            )
            mbWindow.setFrame(menuBarRect, display: true)
        }
        
        if let shadowWindow = shadowWindowController?.window {
            let shadowHeight: CGFloat = 80.0
            let shadowRect = NSRect(
                x: screenFrame.origin.x,
                y: screenFrame.origin.y + screenFrame.height - (menuBarHeight + shadowHeight),
                width: screenFrame.width,
                height: shadowHeight
            )
            shadowWindow.setFrame(shadowRect, display: true)
        }
        
        // Obtain the real user wallpaper
        if let originalURL = WallpaperManager.getOriginalWallpaperURL(screen: screen) {
            // When "Reduce Transparency" is disabled in macOS, set the black-bar wallpaper
            // so WindowServer samples pure black and does not create frosted blur!
            if !NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency {
                _ = WallpaperManager.applyBlackBarWallpaper(from: originalURL, for: screen)
            }
            
            // Crop wallpaper slice from original unblurred image and apply
            let croppedImage = WallpaperManager.cropWallpaper(from: originalURL, for: screen)
            menuBarWindowController?.updateWallpaper(image: croppedImage)
        }
    }
    
    @objc private func refreshAction(_ sender: Any?) {
        refresh()
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newState = !LaunchAtLogin.isEnabled
        LaunchAtLogin.isEnabled = newState
        sender.state = newState ? .on : .off
    }
    
    @objc private func quitAction(_ sender: Any?) {
        restoreWallpaper()
        NSApplication.shared.terminate(self)
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        restoreWallpaper()
    }
    
    private func restoreWallpaper() {
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            WallpaperManager.restoreOriginalWallpaper(screen: screen)
        }
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        launchAtLoginMenuItem?.state = LaunchAtLogin.isEnabled ? .on : .off
    }
    
    public func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
