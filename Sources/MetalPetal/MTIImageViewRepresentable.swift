//
// Copyright (c) Vatsal Manot
//

import MetalKit
import SwiftUI

public struct MTIImageViewRepresentable {
    @Binding public var image: MTIImage?
    
    public init(image: Binding<MTIImage?>) {
        self._image = image
    }
    
    public class Coordinator: NSObject {
        fileprivate var parent: MTIImageViewRepresentable
        
        fileprivate init(parent: MTIImageViewRepresentable) {
            self.parent = parent
        }
    }
}

#if os(macOS)
extension MTIImageViewRepresentable: NSViewRepresentable {
    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    public func makeNSView(context: Context) -> MTIImageView {
        let MTIImageView = MTIImageView()
        
        MTIImageView.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        MTIImageView.drawsImmediately = true
        MTIImageView.image = image
        MTIImageView.setOpaque(false)
        MTIImageView.colorPixelFormat = .bgra8Unorm
        
        return MTIImageView
    }
    
    public func updateNSView(_ nsView: MTIImageView, context: Context) {
        nsView.image = image
    }
}
#else
extension MTIImageViewRepresentable: UIViewRepresentable {
    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    public func makeUIView(context: Context) -> MTIImageView {
        let view = MTIImageView()
        
        view.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        view.image = image
        view.isOpaque = false
        view.colorPixelFormat = .bgra8Unorm
        
        return view
    }
    
    public func updateUIView(_ view: MTIImageView, context: Context) {
        if view.renderView != nil, view._drawsImmediately != true {
            view._drawsImmediately = true
        }
        
        view.image = image
    }
}

extension MTIImageView {
    var _drawsImmediately: Bool {
        get {
            guard let renderView else {
                assertionFailure()
                
                return false
            }
            
            return renderView.isPaused && !renderView.enableSetNeedsDisplay
        } set {
            guard let renderView else {
                assertionFailure()
                
                return
            }
            
            renderView.isPaused = true
            renderView.enableSetNeedsDisplay = false
        }
    }
}
#endif
