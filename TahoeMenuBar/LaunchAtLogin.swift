//
//  LaunchAtLogin.swift
//  ClearMenuBar
//

import Foundation
import ServiceManagement

public enum LaunchAtLogin {
    
    public static var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return false
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        if SMAppService.mainApp.status != .enabled {
                            try SMAppService.mainApp.register()
                        }
                    } else {
                        if SMAppService.mainApp.status == .enabled {
                            try SMAppService.mainApp.unregister()
                        }
                    }
                } catch {
                    NSLog("[TahoeMenuBar] Launch at login error: %@", error.localizedDescription)
                }
            }
        }
    }
}
