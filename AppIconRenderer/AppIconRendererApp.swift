//
//  AppIconRendererApp.swift
//  AppIconRenderer
//
//  Created by Mike Sanford (1540) on 8/2/24.
//

import SwiftUI

let path = "/Users/msanford1540/Developer/tictacspatial/TicTacSpatial-iOS/Assets.xcassets/AppIcon.appiconset"

@main @MainActor
struct AppIconRendererApp: App {
    let render = AppIconRenderer(path: path)

    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                HStack {
                    let length = min(geometry.size.width, geometry.size.height)
                    Image(nsImage: render.macOSExampleImage(length: length))
                        .resizable()
                        .scaledToFit()
                        .border(.black)
                    Image(nsImage: render.iOSExampleImage(length: length))
                        .resizable()
                        .scaledToFit()
                        .border(.black)
                }
            }
            .frame(maxHeight: 384)
            .padding()
            .onAppear {
                render.writeFiles()
            }
        }
        .windowIdealSize(.fitToContent)
    }
}
