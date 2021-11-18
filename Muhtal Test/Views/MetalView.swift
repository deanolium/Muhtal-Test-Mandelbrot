//
//  MetalView.swift
//  Muhtal Test
//
//  Created by Deano License on 15/06/2021.
//

import MetalKit
import SwiftUI

struct MetalView: NSViewRepresentable {
    typealias NSViewType = MTKView
    @Binding var amount: Double
    @Binding var origin: SIMD2<Float>
    @Binding var zoom: Double
    
    func makeCoordinator() -> Coordinator{
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = ZoomableMTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        mtkView.clearColor = MTLClearColor(red: 0, green: 1, blue: 0, alpha: 1)
        mtkView.enableSetNeedsDisplay = true
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        nsView.setNeedsDisplay(.null)
    }
    
    class ZoomableMTKView: MTKView {
        override func scrollWheel(with event: NSEvent) {
            guard event.hasPreciseScrollingDeltas == true else {
                return super.scrollWheel(with: event)
            }
            
            (self.delegate as! Coordinator).changeZoom(by: Float(event.scrollingDeltaY / 1000.0))
        }
    }
    
    // Create the coordinator class to deal with the MTKView config and all that jazz
    class Coordinator: NSObject, MTKViewDelegate {
        var _parent: MetalView
        var _engine: MetalEngine!
        
        init(_ parent: MetalView) {
            _parent = parent
            _engine = MetalEngine()
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func draw(in view: MTKView) {
            var iterations = Int(_parent.amount)
            let aspectHeight = Float(view.drawableSize.height / view.drawableSize.width)
            _engine.render(in: view, iterations: &iterations, center: _parent.origin, scale: Float(1.0/_parent.zoom), aspectRatio: SIMD2<Float>(1.0, aspectHeight))
        }
        
        func changeZoom(by amount: Float) {
            _parent.zoom = max(_parent.zoom * (1.0 + Double(amount)), 0.1)
            
        }
    }
}
