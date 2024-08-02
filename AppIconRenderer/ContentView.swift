//
//  ContentView.swift
//  AppIconRenderer
//
//  Created by Mike Sanford (1540) on 8/2/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

enum Platform {
    case macOS, iOS, visionOS

    var sizes: [Int] {
        switch self {
        case .iOS:
            []
        }
    }
}

struct AppIcon {
    let platform: Platform
    let size:

    func drawMacBackground() {
        
    }
}

private final class AppIconRenderer {
    
}
