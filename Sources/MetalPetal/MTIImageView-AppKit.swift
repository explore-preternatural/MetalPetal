import MetalKit
import SwiftUI

#if os(macOS)
import Cocoa
#endif

#if os(macOS)
public class MTIImageView: NSView {
    private weak var renderView: MTKView?
    
    private var screenScale: CGFloat = 1.0
    private var contextCreationError: Error?
    
    public var context: MTIContext?
    public var resizingMode: MTIDrawableRenderingResizingMode = .aspect
    public var automaticallyCreatesContext = true
    public var drawsImmediately = false {
        didSet {
            guard let renderView = renderView else {
                return
            }
            
            if drawsImmediately {
                renderView.isPaused = true
                renderView.enableSetNeedsDisplay = false
            } else {
                renderView.isPaused = true
                renderView.enableSetNeedsDisplay = true
            }
        }
    }
    
    public var image: MTIImage? {
        didSet {
            if image != oldValue {
                updateContentScaleFactor()
                setNeedsRedraw()
            }
        }
    }
    
    public var colorPixelFormat: MTLPixelFormat {
        get {
            renderView?.colorPixelFormat ?? .invalid
        } set {
            guard let renderView = renderView, renderView.colorPixelFormat != newValue else {
                return
            }
            
            renderView.colorPixelFormat = newValue
            
            setNeedsRedraw()
        }
    }
    
    public var clearColor: MTLClearColor {
        get {
            renderView?.clearColor ?? MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        } set {
            guard let renderView = renderView else {
                return
            }
            
            if renderView.clearColor.red != newValue.red ||
                renderView.clearColor.green != newValue.green ||
                renderView.clearColor.blue != newValue.blue ||
                renderView.clearColor.alpha != newValue.alpha
            {
                renderView.clearColor = newValue
                renderView.layer?.backgroundColor = .clear
                
                setNeedsRedraw()
            }
        }
    }
    
    override public init(frame: NSRect) {
        super.init(frame: frame)
        
        setupImageView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupImageView()
    }
    
    private func setupImageView() {
        let renderView = MTKView(frame: bounds, device: nil)
        
        renderView.autoresizingMask = [.width, .height]
        renderView.delegate = self
        renderView.isPaused = true
        renderView.enableSetNeedsDisplay = true
        
        addSubview(renderView)
        
        self.renderView = renderView
        
        wantsLayer = true
        layer?.isOpaque = false
        
        renderView.wantsLayer = true
        renderView.layer?.isOpaque = false
    }
    
    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let screen = window?.screen {
            screenScale = screen.backingScaleFactor
        } else {
            screenScale = 1.0
        }
    }
    
    override public var isOpaque: Bool {
        layer?.isOpaque ?? false
    }
    
    public func setOpaque(_ opaque: Bool) {
        if layer?.isOpaque != opaque {
            layer?.isOpaque = opaque
            
            setNeedsRedraw()
        }
    }
    
    override public var isHidden: Bool {
        didSet {
            if oldValue {
                setNeedsRedraw()
            }
        }
    }
    
    override public var alphaValue: CGFloat {
        didSet {
            if oldValue <= 0 {
                setNeedsRedraw()
            }
        }
    }
    
    private func setupContextIfNeeded() {
        guard context == nil, contextCreationError == nil, automaticallyCreatesContext else { return }
        
        do {
            guard let device = MTLCreateSystemDefaultDevice() else {
                throw NSError(domain: "MTIImageViewError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create Metal device"])
            }
            
            context = try MTIContext(device: device)
            renderView?.device = context?.device
        } catch {
            contextCreationError = error
        }
    }
    
    private func updateContentScaleFactor() {
        guard
            let renderView = renderView,
            renderView.frame.size.width > 0,
            renderView.frame.size.height > 0,
            let image = image,
            image.size.width > 0,
            image.size.height > 0,
            window?.screen != nil
        else {
            return
        }
        
        let imageSize = image.size
        let widthScale = imageSize.width / renderView.bounds.size.width
        let heightScale = imageSize.height / renderView.bounds.size.height
        let nativeScale = screenScale
        let scale = max(min(max(widthScale, heightScale), nativeScale), 1.0)
        
        if abs(renderView.layer?.contentsScale ?? 0 - scale) > 0.00001 {
            renderView.layer?.contentsScale = scale
        }
    }
    
    override public func layout() {
        super.layout()
        
        updateContentScaleFactor()
        setNeedsRedraw()
    }
    
    func setNeedsRedraw() {
        guard let renderView = renderView else {
            return
        }
        
        if drawsImmediately {
            renderView.draw()
        } else {
            renderView.setNeedsDisplay(renderView.bounds)
        }
    }
}

// MARK: - Delegate

extension MTIImageView: MTKViewDelegate {
    public func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {
        // Implementation not provided in the original code
    }
    
    public func draw(in view: MTKView) {
        guard !isHidden, alphaValue > 0 else {
            return
        }
        
        setupContextIfNeeded()
        
        guard let context = context else {
            return
        }
        
        if let imageToRender = image {
            let request = MTIDrawableRenderingRequest(drawableProvider: view, resizingMode: resizingMode)
            
            do {
                try context.render(imageToRender, toDrawableWithRequest: request)
            } catch {
                debugPrint("\(self): Failed to render image \(imageToRender) - \(error)")
            }
        } else {
            guard
                let renderPassDescriptor = view.currentRenderPassDescriptor,
                let drawable = view.currentDrawable
            else {
                return
            }
            
            let commandBuffer = context.commandQueue.makeCommandBuffer()
            let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            commandEncoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}

#endif
