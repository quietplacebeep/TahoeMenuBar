//
//  ShadowWindowController.swift
//  ClearMenuBar
//

import AppKit

public class ShadowWindow: NSWindow {
    
    public override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }
        
    public func setup() {
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isOpaque = false
        hasShadow = false
        
        level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenNone, .stationary]
        backgroundColor = NSColor.clear
        alphaValue = 1.0
        ignoresMouseEvents = true
        self.orderFrontRegardless()
    }
}

public class ShadowWindowController: NSWindowController {
    
    public init(window: ShadowWindow) {
        super.init(window: window)
        
        let shadowView = ShadowLayerView(frame: window.contentView?.bounds ?? NSRect(origin: .zero, size: window.frame.size))
        shadowView.autoresizingMask = [.width, .height]

        window.contentView = shadowView
        window.setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
