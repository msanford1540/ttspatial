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
            HStack {
                Image(nsImage: render.macOSExampleImage)
                    .resizable()
                    .scaledToFit()
                    .border(.black)
                Image(nsImage: render.iOSExampleImage)
                    .resizable()
                    .scaledToFit()
                    .border(.black)
            }
            .frame(height: 512)
            .padding()
            .onAppear {
                render.writeFiles()
            }
        }
        .windowIdealSize(.fitToContent)
    }
}
