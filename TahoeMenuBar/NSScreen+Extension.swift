//
//  NSScreen+Extension.swift
//  ClearMenuBar
//

import AppKit

public extension NSScreen {
    
    var hasNotch: Bool {
        if #available(macOS 12.0, *) {
            return self.safeAreaInsets.top > 0
        }
        return false
    }
    
    var menuBarHeight: CGFloat {
        let minHeight: CGFloat = self.hasNotch ? 37.0 : 24.0
        return max(visibleMenuBarHeight, minHeight)
    }
    
    var visibleMenuBarHeight: CGFloat {
        let dockHeight = max(0, self.visibleFrame.origin.y - self.frame.origin.y)
        let computed = self.frame.height - self.visibleFrame.height - dockHeight - 1.0
        return max(0, computed)
    }
}
