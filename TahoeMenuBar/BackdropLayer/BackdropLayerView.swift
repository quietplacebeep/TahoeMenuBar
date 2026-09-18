//
//  BackdropLayerView.swift
//  ClearMenuBar
//
//  Preserves the CoreAnimation backdrop & wallpaper blend mechanism from ClearMenuBar.
//

import AppKit
import QuartzCore

public class BackdropLayerView: NSVisualEffectView {
    
    private var backdrop: CABackdropLayer?
    private var tint: CALayer?
    private var container: CALayer?
    private var wallpaper: CALayer?
    private var wallpaperContainer: CALayer?
    
    public var effect: OverlayEffect = .clear {
        didSet {
            self.tint?.backgroundColor = self.effect.tintColor().cgColor
        }
    }
    
    public override var blendingMode: NSVisualEffectView.BlendingMode {
        get { return self.window?.contentView == self ? .behindWindow : .withinWindow }
        set { }
    }
    
    public override var material: NSVisualEffectView.Material {
        get { return .appearanceBased }
        set { }
    }
    
    public override var state: NSVisualEffectView.State {
        get { return .active }
        set { }
    }
    
    public override var frame: NSRect {
        didSet {
            updateSublayerFrames()
        }
    }
    
    public override var bounds: NSRect {
        didSet {
            updateSublayerFrames()
        }
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.commonInit()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .onSetNeedsDisplay
        self.layer?.masksToBounds = true
        self.layer?.name = "view"
        
        self.tint = CALayer()
        self.tint?.name = "tint"
        
        self.wallpaperContainer = CALayer()
        self.wallpaperContainer?.name = "wallpaperContainer"
        
        self.wallpaper = CALayer()
        self.wallpaper?.name = "wallpaper"
        
        // CIFilters on wallpaper layer as in ClearMenuBar
        var wallpaperFilters: [CIFilter] = []
        if let vibranceFilter = CIFilter(name: "CIVibrance") {
            vibranceFilter.name = "vibrance"
            wallpaperFilters.append(vibranceFilter)
        }
        if let colorControlsFilter = CIFilter(name: "CIColorControls") {
            colorControlsFilter.name = "colorControls"
            wallpaperFilters.append(colorControlsFilter)
        }
        if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
            exposureFilter.name = "exposureAdjust"
            wallpaperFilters.append(exposureFilter)
        }
        self.wallpaper?.filters = wallpaperFilters
        
        self.wallpaperContainer?.sublayers = [self.wallpaper!, self.tint!]
        self.wallpaperContainer?.compositingFilter = CAFilter(type: kCAFilterScreenBlendMode)
        
        // Tell NSVisualEffectView to remain clear
        super.state = .active
        super.blendingMode = .behindWindow
        super.material = .appearanceBased
        self.setValue(true, forKey: "clear")
        
        // Backdrop layer sampling window server framebuffer behind menu bar
        self.backdrop = CABackdropLayer()
        self.backdrop?.masksToBounds = true
        self.backdrop?.name = "backdrop"
        self.backdrop?.allowsGroupOpacity = true
        self.backdrop?.allowsEdgeAntialiasing = false
        self.backdrop?.disablesOccludedBackdropBlurs = true
        self.backdrop?.ignoresOffscreenGroups = false
        self.backdrop?.allowsInPlaceFiltering = false
        self.backdrop?.setValue(1, forKey: "scale")
        self.backdrop?.setValue(0.1, forKey: "bleedAmount")
        self.backdrop?.windowServerAware = true
        
        var backdropFilters: [CAFilter] = []
        if let brightnessFilter = CAFilter(type: kCAFilterColorBrightness) {
            brightnessFilter.name = "brightness"
            backdropFilters.append(brightnessFilter)
        }
        if let contrastFilter = CAFilter(type: kCAFilterColorContrast) {
            contrastFilter.name = "contrast"
            backdropFilters.append(contrastFilter)
        }
        if let invertFilter = CAFilter(type: kCAFilterColorInvert) {
            invertFilter.name = "invert"
            backdropFilters.append(invertFilter)
        }
        if let hueRotateFilter = CAFilter(type: kCAFilterColorHueRotate) {
            hueRotateFilter.name = "hueRotate"
            hueRotateFilter.setValue(3.14, forKey: "inputAngle")
            backdropFilters.append(hueRotateFilter)
        }
        self.backdrop?.filters = backdropFilters
        
        self.container = CALayer()
        self.container?.name = "container"
        self.container?.masksToBounds = true
        self.container?.allowsEdgeAntialiasing = true
        self.container?.sublayers = [self.backdrop!, self.wallpaperContainer!]
        
        self.layer?.insertSublayer(self.container!, at: 0)
        
        updateSublayerFrames()
        viewDidChangeEffectiveAppearance()
        viewDidChangeBackingProperties()
    }
    
    public func updateSublayerFrames() {
        let b = self.bounds
        guard b.width > 0, b.height > 0 else { return }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.0)
        self.container?.frame = b
        self.backdrop?.frame = b
        self.tint?.frame = b
        self.wallpaper?.frame = b
        self.wallpaperContainer?.frame = b
        CATransaction.commit()
    }
    
    public func updateWallpaper(image: CGImage?) {
        updateSublayerFrames()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.0)
        self.wallpaper?.contents = image
        CATransaction.commit()
    }
    
    public override func viewDidChangeEffectiveAppearance() {
        let systemAppearance = NSApplication.shared.effectiveAppearance
        let isDark = (systemAppearance.name == .darkAqua)
        let reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        
        if isDark {
            self.wallpaperContainer?.compositingFilter = CAFilter(type: kCAFilterScreenBlendMode)
            self.effect = .darkShadow
            self.backdrop?.setValue(false, forKeyPath: "filters.invert.enabled")
            self.backdrop?.setValue(false, forKeyPath: "filters.hueRotate.enabled")
            if !reduceTransparency {
                self.backdrop?.setValue(0.0, forKeyPath: "filters.brightness.inputAmount")
                self.backdrop?.setValue(1.0, forKeyPath: "filters.contrast.inputAmount")
            } else {
                self.backdrop?.setValue(-0.063, forKeyPath: "filters.brightness.inputAmount")
                self.backdrop?.setValue(1.14, forKeyPath: "filters.contrast.inputAmount")
            }
        } else {
            self.wallpaperContainer?.compositingFilter = CAFilter(type: kCAFilterMultiplyBlendMode)
            self.effect = .lightShadow
            if !reduceTransparency {
                self.backdrop?.setValue(true, forKeyPath: "filters.invert.enabled")
                self.backdrop?.setValue(true, forKeyPath: "filters.hueRotate.enabled")
                self.backdrop?.setValue(0.0, forKeyPath: "filters.brightness.inputAmount")
                self.backdrop?.setValue(1.0, forKeyPath: "filters.contrast.inputAmount")
            } else {
                self.backdrop?.setValue(false, forKeyPath: "filters.invert.enabled")
                self.backdrop?.setValue(false, forKeyPath: "filters.hueRotate.enabled")
                self.backdrop?.setValue(0.0919, forKeyPath: "filters.brightness.inputAmount")
                self.backdrop?.setValue(1.166, forKeyPath: "filters.contrast.inputAmount")
            }
        }
    }
    
    public override func layout() {
        super.layout()
        updateSublayerFrames()
    }
    
    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateSublayerFrames()
    }
    
    public override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        let scale = self.window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1.0
        self.layer?.contentsScale = scale
        self.container?.contentsScale = scale
        self.backdrop?.contentsScale = scale
        self.tint?.contentsScale = scale
        self.wallpaper?.contentsScale = scale
        self.wallpaperContainer?.contentsScale = scale
    }
}
