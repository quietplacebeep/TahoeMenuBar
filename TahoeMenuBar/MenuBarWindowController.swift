//
//  MenuBarWindowController.swift
//  ClearMenuBar
//

import AppKit

public class MenuBarWindow: NSWindow {
    
    public override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }
    
    public func setup() {
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isOpaque = false
        hasShadow = false
        
        level = NSWindow.Level.statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenNone]
        backgroundColor = NSColor.clear
        alphaValue = 1.0
        ignoresMouseEvents = true
        self.orderFrontRegardless()
    }
}

public class MenuBarWindowController: NSWindowController {
    
    public let backdropView: BackdropLayerView
    
    public init(window: MenuBarWindow) {
        let initialFrame = NSRect(origin: .zero, size: window.frame.size)
        self.backdropView = BackdropLayerView(frame: initialFrame)
        super.init(window: window)
        
        backdropView.layerUsesCoreImageFilters = true
        backdropView.autoresizingMask = [.width, .height]
        
        window.contentView = backdropView
        window.setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateWallpaper(image: CGImage?) {
        backdropView.updateWallpaper(image: image)
    }
}
