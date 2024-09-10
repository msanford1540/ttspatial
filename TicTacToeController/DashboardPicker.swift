//
//  DashboardPicker.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/28/24.
//

import SwiftUI
import TicTacToeEngine

public protocol DashboardPickerItem: Identifiable, Hashable {
    var name: String { get }
    var imageName: String { get }
}

public struct DashboardPicker<Item: DashboardPickerItem>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let title: String
    private let items: [Item]
    @Binding private var selection: Item

    public init(_ title: String, items: [Item], selection: Binding<Item>) {
        self.title = title
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { source in
                Button {
                    selection = source
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: source.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: labelWidth, height: labelImageHeight)
                        Text(source.name)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .font(.title)
                    }
                    .frame(maxHeight: labelMaxHeight)
                    .tag(source)
                    .padding(3)
                    .background(selection == source ? selectedColor : .clearHittable)
                    .cornerRadius(labelCornerRadius)
                    .foregroundColor(textColor)
                }
                .buttonStyle(.plain)
                .animation(.default, value: selection)
            }
        }
        .padding(4)
        .background(backgroundColor)
        .cornerRadius(pickerCornerRadius)
    }

    private var labelWidth: CGFloat {
#if os(visionOS)
        160
#elseif os(macOS)
        64
#elseif os(iOS)
        54
#endif
    }

    private var labelImageHeight: CGFloat {
#if os(visionOS)
        48
#else
        30
#endif
    }

    private var labelMaxHeight: CGFloat {
#if os(visionOS)
        labelImageHeight + 48
#else
        labelImageHeight + 26
#endif
    }

    private var labelCornerRadius: CGFloat {
#if os(visionOS)
        42
#else
        14
#endif
    }

    private var pickerCornerRadius: CGFloat {
        labelCornerRadius + 2
    }

    private var textColor: Color {
#if os(visionOS)
        .white
#else
        switch colorScheme {
        case .light: .black
        case .dark: .white
        @unknown default: .black
        }
#endif
    }

    private var selectedColor: Color {
#if os(visionOS)
        .white.opacity(0.333)
#else
        switch colorScheme {
        case .light: .white.opacity(0.667)
        case .dark: .white.opacity(0.333)
        @unknown default: .white.opacity(0.667)
        }
#endif
    }

    private var backgroundColor: Color {
#if os(visionOS)
        .black.opacity(0.333)
#else
        switch colorScheme {
        case .light: .gray.opacity(0.333)
        case .dark: .init(white: 0.333).opacity(0.5)
        @unknown default: .black.opacity(0.333)
        }
#endif
    }
}

extension GameboardDimensions: DashboardPickerItem {
    public var name: String {
        switch self {
        case .grid3:
            Localized.Dashboard.twoDimension
        case .cube4:
            Localized.Dashboard.threeDimension
        }
    }

    public var imageName: String {
        switch self {
        case .grid3:
            "square.fill"
        case .cube4:
            "square.stack.3d.down.forward.fill"
        }
    }
}

extension BotLevel: DashboardPickerItem {
    public var name: String {
        switch self {
        case .easy:
            Localized.BotLevel.easy
        case .medium:
            Localized.BotLevel.medium
        case .hard:
            Localized.BotLevel.advanced
        }
    }

    public var imageName: String {
        switch self {
        case .easy:
            "1.circle"
        case .medium:
            "2.circle"
        case .hard:
            "3.circle"
        }
    }
}

private extension Color {
    static var clearHittable: Color {
        .init(white: 1, opacity: 0.01)
    }
}
