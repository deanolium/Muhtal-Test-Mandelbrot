//
//  shaders.metal
//  Muhtal Test
//
//  Created by Deano License on 25/06/2021.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[ position ]];
    float2 coords;
};


struct MandelbrotBounds {
    float2 origin;
    float2 size;
};

vertex VertexOut basic_vertex_shader(
                                    const device simd_float3 *vertices [[ buffer(0) ]],
                                    const device MandelbrotBounds &bounds [[ buffer(1) ]],
                                    unsigned int vertex_id [[ vertex_id ]]
                                  ) {
    VertexOut out = VertexOut();
    out.position = float4(vertices[vertex_id], 1.0);
    out.coords = (out.position.xy / 2.0) * bounds.size + bounds.origin;
    return out;
}


fragment half4 textured_mandelbrot_fragment_shader(
                                                   VertexOut vIn [[ stage_in ]],
                                                   constant int &maxIterations [[ buffer(0) ]],
                                                   texture2d<half> colorTexture [[ texture(0) ]]
                                          ) {
    half4 out = half4(0, 0, 0, 1);
    
    constexpr sampler textureSampler;
    
    // convert the vIn position to mandelbrot space
    float x0 = vIn.coords.x;
    float y0 = vIn.coords.y;

    float x = 0.0;
    float y = 0.0;
    int iterations = 0;

    while(iterations < maxIterations && (x*x + y*y <= 4)) {
        float newX = x*x - y*y + x0;
        y = 2 * x * y + y0;
        x = newX;
        iterations++;
    }

    out = colorTexture.sample(textureSampler, float2(1.0 - (float(iterations) / float(maxIterations)), 0.0));
    
    return out;
}
