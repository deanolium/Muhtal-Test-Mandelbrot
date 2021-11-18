//
//  ContentView.swift
//  Muhtal Test
//
//  Created by Deano License on 15/06/2021.
//

import SwiftUI

struct ContentView: View {
    @State private var sliderValue = 100.0
    @State private var savedOrigin = SIMD2<Float>(-1.5, 0.0)
    @State private var origin = SIMD2<Float>(-1.5, 0.0)
    @State private var zoom = 1.0

    var body: some View {
        VStack {
            GeometryReader() { geometry in
                MetalView(amount: $sliderValue, origin: $origin, zoom: $zoom)
                    .gesture(DragGesture()
                        .onChanged({ amount in
                            origin.x = savedOrigin.x - Float(amount.translation.width/(geometry.size.width * zoom))
                            origin.y = savedOrigin.y + Float(amount.translation.height/(geometry.size.height * zoom))
                                                     * Float(geometry.size.height/geometry.size.width)
                        })
                        .onEnded({ amount in
                            savedOrigin.x = origin.x
                            savedOrigin.y = origin.y
                        })
                    )
            }
                
            GroupBox() {
                VStack {
                    Slider(value: $sliderValue, in: 10...2000)
                    Text(String(format: "Iterations %.0f", sliderValue))
                    Divider()
                    Text(String(format: "Center Point: (%0.4f,%0.4f)", origin.x, origin.y))
                    Text(String(format: "Zoom: %0.2f", zoom))
                }
            }
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
