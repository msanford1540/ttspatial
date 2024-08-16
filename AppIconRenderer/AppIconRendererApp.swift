//
//  AppIconRendererApp.swift
//  AppIconRenderer
//
//  Created by Mike Sanford (1540) on 8/2/24.
//

import SwiftUI

private let folder = "/Users/msanford1540/Developer/tictacspatial"
let iOSMacOSPath = "\(folder)/TicTacSpatial-iOS/Assets.xcassets/AppIcon.appiconset"
let visionOSPath = "\(folder)/TicTacSpatial-visionOS/Assets.xcassets/AppIcon.solidimagestack"

@main @MainActor
struct AppIconRendererApp: App {
    let render = AppIconRenderer(iOSMacOSPath: iOSMacOSPath, visionOSPath: visionOSPath)

    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                HStack {
                    let length = min(geometry.size.width, geometry.size.height)
                    let secondaryLength = length * 0.333
                    VStack {
                        let topImageLength = length - secondaryLength - 16
                        Image(nsImage: render.macOSExampleImage(length: topImageLength, languageDirection: .leftToRight))
                            .frame(width: topImageLength, height: topImageLength)
                            .border(.black)
                        Image(nsImage: render.macOSExampleImage(length: secondaryLength, languageDirection: .rightToLeft))
                            .frame(width: secondaryLength, height: secondaryLength)
                            .border(.black)
                    }
                    VStack {
                        Image(nsImage: render.iOSExampleImage(length: length, appearanceType: nil))
                            .resizable()
                            .scaledToFit()
                        HStack {
                            Image(nsImage: render.iOSExampleImage(length: length, appearanceType: .dark))
                                .resizable()
                                .scaledToFit()
                                .border(.black)
                            Image(nsImage: render.iOSExampleImage(length: length, appearanceType: .tinted))
                                .resizable()
                                .scaledToFit()
                                .border(.black)
                        }
                        .frame(height: secondaryLength)
                    }
                    VStack {
                        Image(nsImage: render.visionOSExampleImage(length: length, layer: .all))
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                        HStack {
                            Image(nsImage: render.visionOSExampleImage(length: length, layer: .front))
                                .resizable()
                                .scaledToFit()
                                .overlay(Circle().stroke(.black))
                           Image(nsImage: render.visionOSExampleImage(length: length, layer: .middle))
                                .resizable()
                                .scaledToFit()
                                .overlay(Circle().stroke(.black))
                            Image(nsImage: render.visionOSExampleImage(length: length, layer: .back))
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                        }
                        .frame(height: secondaryLength)
                    }
                    Spacer()
                }
            }
            .frame(maxHeight: 1024)
            .padding()
            .task {
                render.writeFiles()
            }
        }
        .windowIdealSize(.fitToContent)
    }
}
