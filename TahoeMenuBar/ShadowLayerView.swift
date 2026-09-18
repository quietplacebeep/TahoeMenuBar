//
//  ShadowLayerView.swift
//  ClearMenuBar
//

import AppKit

public class ShadowLayerView: NSView {

    private var tint: CALayer? = nil
    private var gradient: CAGradientLayer? = nil
    
    public var effect: OverlayEffect = .darkShadow {
        didSet {
            self.tint?.backgroundColor = self.effect.tintColor().cgColor
        }
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
        
        self.tint = CALayer()
        self.tint?.name = "shadowTint"
        
        let grad = CAGradientLayer()
        grad.frame = bounds

        grad.colors = (0...60).map { i in
            let t = Double(i) / 60.0
            let eased = t * t * (3.0 - 2.0 * t)
            return NSColor.black.withAlphaComponent(CGFloat(eased)).cgColor
        }

        grad.startPoint = CGPoint(x: 0.5, y: 0.0)
        grad.endPoint = CGPoint(x: 0.5, y: 1.0)
        grad.type = .axial
        self.gradient = grad
        
        self.tint?.mask = grad
        layer?.addSublayer(self.tint!)
        
        updateSublayerFrames()
        viewDidChangeEffectiveAppearance()
        viewDidChangeBackingProperties()
    }
    
    public func updateSublayerFrames() {
        let b = self.bounds
        guard b.width > 0, b.height > 0 else { return }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.0)
        self.tint?.frame = b
        self.gradient?.frame = b
        CATransaction.commit()
    }
    
    public override func viewDidChangeEffectiveAppearance() {
        let systemAppearance = NSApplication.shared.effectiveAppearance
        if systemAppearance.name == .darkAqua {
            self.effect = .darkShadow
        } else {
            self.effect = .lightShadow
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
        self.tint?.contentsScale = scale
        self.gradient?.contentsScale = scale
    }
}
