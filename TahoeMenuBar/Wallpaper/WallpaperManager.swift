//
//  WallpaperManager.swift
//  ClearMenuBar
//

import AppKit

public enum WallpaperManager {
    
    private static let originalWallpaperKey = "ClearMenuBarOriginalWallpaperPath"
    
    public static func applicationSupportDirectory() -> URL? {
        let fileManager = FileManager.default
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = baseURL.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.quietplacebeep.TahoeMenuBar")
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }
    
    /// Returns true if the given URL points to our managed wallpaper in Application Support.
    public static func isManagedWallpaper(url: URL) -> Bool {
        if let appDir = applicationSupportDirectory() {
            let normalizedURL = url.resolvingSymlinksInPath().standardizedFileURL
            let normalizedAppDir = appDir.resolvingSymlinksInPath().standardizedFileURL
            if normalizedURL.path.hasPrefix(normalizedAppDir.path) {
                return true
            }
        }
        return url.lastPathComponent.contains("Managed by TahoeMenuBar")
    }
    
    /// Retrieves the original user wallpaper URL, recording it if not already stored.
    public static func getOriginalWallpaperURL(screen: NSScreen) -> URL? {
        guard let currentURL = NSWorkspace.shared.desktopImageURL(for: screen) else {
            return nil
        }
        
        if isManagedWallpaper(url: currentURL) {
            if let storedPath = UserDefaults.standard.string(forKey: originalWallpaperKey) {
                let storedURL = URL(fileURLWithPath: storedPath)
                if FileManager.default.fileExists(atPath: storedURL.path) {
                    return storedURL
                }
            }
            return nil
        } else {
            UserDefaults.standard.set(currentURL.path, forKey: originalWallpaperKey)
            return currentURL
        }
    }
    
    /// Restores the user's original wallpaper upon quit.
    public static func restoreOriginalWallpaper(screen: NSScreen) {
        if let storedPath = UserDefaults.standard.string(forKey: originalWallpaperKey) {
            let originalURL = URL(fileURLWithPath: storedPath)
            if FileManager.default.fileExists(atPath: originalURL.path) {
                try? NSWorkspace.shared.setDesktopImageURL(originalURL, for: screen, options: [:])
            }
        }
    }
    
    /// Crops the exact slice of the wallpaper that sits behind the menu bar for the given screen.
    public static func cropWallpaper(from imageURL: URL, for screen: NSScreen) -> CGImage? {
        guard let wallpaperImage = NSImage(contentsOf: imageURL),
              let wallpaperCGImage = wallpaperImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let scale = screen.backingScaleFactor
        let screenWidth = screen.frame.width * scale
        let screenHeight = screen.frame.height * scale
        let menuBarHeight = screen.menuBarHeight * scale
        
        guard screenWidth > 0, screenHeight > 0, menuBarHeight > 0,
              wallpaperCGImage.width > 0, wallpaperCGImage.height > 0 else {
            return nil
        }
        
        let screenProportion = screenWidth / screenHeight
        let wallpaperProportion = CGFloat(wallpaperCGImage.width) / CGFloat(wallpaperCGImage.height)
        
        let drawWidth: CGFloat
        let drawHeight: CGFloat
        let drawX: CGFloat
        let drawY: CGFloat
        
        if wallpaperProportion >= screenProportion {
            drawHeight = screenHeight
            drawWidth = (screenHeight / CGFloat(wallpaperCGImage.height)) * CGFloat(wallpaperCGImage.width)
            drawX = (screenWidth - drawWidth) / 2.0
            drawY = 0
        } else {
            drawWidth = screenWidth
            drawHeight = (screenWidth / CGFloat(wallpaperCGImage.width)) * CGFloat(wallpaperCGImage.height)
            drawX = 0
            drawY = (screenHeight - drawHeight) / 2.0
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(screenWidth),
            height: Int(screenHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(wallpaperCGImage, in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))
        
        guard let renderedCGImage = context.makeImage() else { return nil }
        let cropRect = CGRect(x: 0, y: 0, width: screenWidth, height: menuBarHeight)
        return renderedCGImage.cropping(to: cropRect)
    }
    
    /// Generates a version of the wallpaper with a black rectangle behind the menu bar,
    /// and sets it as the desktop wallpaper. This enables true transparency without needing
    /// "Reduce Transparency" enabled in macOS System Settings.
    public static func applyBlackBarWallpaper(from originalURL: URL, for screen: NSScreen) -> Bool {
        guard let wallpaperImage = NSImage(contentsOf: originalURL),
              let wallpaperCGImage = wallpaperImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }
        
        let scale = screen.backingScaleFactor
        let screenWidth = screen.frame.width * scale
        let screenHeight = screen.frame.height * scale
        let menuBarHeight = screen.menuBarHeight * scale
        
        guard screenWidth > 0, screenHeight > 0, menuBarHeight > 0,
              wallpaperCGImage.width > 0, wallpaperCGImage.height > 0 else {
            return false
        }
        
        let screenProportion = screenWidth / screenHeight
        let wallpaperProportion = CGFloat(wallpaperCGImage.width) / CGFloat(wallpaperCGImage.height)
        
        let drawWidth: CGFloat
        let drawHeight: CGFloat
        let drawX: CGFloat
        let drawY: CGFloat
        
        if wallpaperProportion >= screenProportion {
            drawHeight = screenHeight
            drawWidth = (screenHeight / CGFloat(wallpaperCGImage.height)) * CGFloat(wallpaperCGImage.width)
            drawX = (screenWidth - drawWidth) / 2.0
            drawY = 0
        } else {
            drawWidth = screenWidth
            drawHeight = (screenWidth / CGFloat(wallpaperCGImage.width)) * CGFloat(wallpaperCGImage.height)
            drawX = 0
            drawY = (screenHeight - drawHeight) / 2.0
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(screenWidth),
            height: Int(screenHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }
        
        context.interpolationQuality = .high
        context.draw(wallpaperCGImage, in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))
        
        // Solid black bar behind the menu bar (top of screen in CGContext)
        let blackRect = CGRect(x: 0, y: screenHeight - menuBarHeight, width: screenWidth, height: menuBarHeight)
        context.setFillColor(NSColor.black.cgColor)
        context.fill(blackRect)
        
        guard let modifiedCGImage = context.makeImage(),
              let appDir = applicationSupportDirectory() else {
            return false
        }
        
        let rep = NSBitmapImageRep(cgImage: modifiedCGImage)
        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            return false
        }
        
        let fileURL = appDir.appendingPathComponent("Managed by TahoeMenuBar.png")
        do {
            try pngData.write(to: fileURL)
            try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
            return true
        } catch {
            NSLog("[TahoeMenuBar] Failed to set modified wallpaper: %@", error.localizedDescription)
            return false
        }
    }
}
