import MetalKit

struct MandelbrotBounds {
    var origin: SIMD2<Float>
    var size: SIMD2<Float>
}

struct MetalEngine {
    private var _device: MTLDevice!
    private var _commandQueue: MTLCommandQueue!
    private var _vertexBuffer: MTLBuffer!
    private var _vertexIndexBuffer: MTLBuffer!
    private var _texture: MTLTexture?
    private var _pipeline: MTLRenderPipelineState!
        
    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            _device = device
        }
        
        _commandQueue = _device.makeCommandQueue()!
                    
        setupQuad()
        setupPipeline()
    }

    mutating func setupQuad() {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-1.0, -1.0,  0.0),
            SIMD3<Float>( 1.0,  1.0,  0.0),
            SIMD3<Float>( 1.0, -1.0,  0.0),
            SIMD3<Float>(-1.0,  1.0,  0.0)
        ]
        
        let indices: [uint16] = [
            0, 1, 2,
            0, 3, 1
        ]
        
        _vertexBuffer = _device.makeBuffer(bytes: vertices, length: MemoryLayout<SIMD3<Float>>.stride * vertices.count, options: [])
        _vertexIndexBuffer = _device.makeBuffer(bytes: indices, length: MemoryLayout<uint16>.stride * indices.count, options: [])
    }
    
    mutating func setupPipeline() {
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()

        let metalLibrary = _device.makeDefaultLibrary()

        renderPipelineDescriptor.vertexFunction = metalLibrary?.makeFunction(name: "basic_vertex_shader")
        renderPipelineDescriptor.fragmentFunction = metalLibrary?.makeFunction(name: "textured_mandelbrot_fragment_shader")
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
        let textureLoader = MTKTextureLoader(device: _device)
        let texture = try? textureLoader.newTexture(name: "mandlebrot-colors", scaleFactor: 1.0, bundle: nil, options: [.SRGB: true])
            
        if let texture = texture {
            self._texture = texture
        }
        
        _pipeline = try! _device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    
    func render(in view: MTKView, iterations: inout Int, center: SIMD2<Float>, scale: Float, aspectRatio: SIMD2<Float> ) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = _commandQueue.makeCommandBuffer(),
              let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        descriptor.colorAttachments[0].loadAction = .dontCare
        descriptor.colorAttachments[0].storeAction = .store
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
                                                        
        encoder.setRenderPipelineState(_pipeline)
        encoder.setCullMode(.back)
        
        encoder.setVertexBuffer(_vertexBuffer, offset: 0, index: 0)

        // TODO: Add in scaling, and then calculate the topLeft in terms of view dimensions and scaling
        let shaderScale = aspectRatio * scale;
        
        var bounds = MandelbrotBounds(origin: center, size: shaderScale)
        encoder.setVertexBytes(&bounds, length: MemoryLayout<MandelbrotBounds>.size, index: 1)
        
        encoder.setFragmentBytes(&iterations, length: MemoryLayout<Int>.size, index: 0)
        
        if let texture = _texture {
            encoder.setFragmentTexture(texture, index: 0)
        }
        
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: _vertexIndexBuffer, indexBufferOffset: 0)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
