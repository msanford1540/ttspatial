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
                    VStack {
                        Image(nsImage: render.macOSExampleImage(length: length, languageDirection: .leftToRight))
                            .resizable()
                            .scaledToFit()
                            .border(.black)
                        Image(nsImage: render.macOSExampleImage(length: length, languageDirection: .rightToLeft))
                            .resizable()
                            .scaledToFit()
                            .border(.black)
                    }
                    VStack {
                        Image(nsImage: render.iOSExampleImage(length: length, languageDirection: .leftToRight))
                            .resizable()
                            .scaledToFit()
                            .border(.black)
                        Image(nsImage: render.iOSExampleImage(length: length, languageDirection: .rightToLeft))
                            .resizable()
                            .scaledToFit()
                            .border(.black)
                    }
                }
            }
            .frame(maxHeight: 1024)
            .padding()
            .onAppear {
                render.writeFiles()
            }
        }
        .windowIdealSize(.fitToContent)
    }
}
