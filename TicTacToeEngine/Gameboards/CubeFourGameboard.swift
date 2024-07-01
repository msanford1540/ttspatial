//
//  CubeFourGameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/22/24.
//

public struct CubeFourGameboard: GameboardProtocol {
    public typealias Location = CubeFourLocation
    public typealias WinningLine = CubeFourWinningLine
    public typealias Snapshot = CubeFourGameboardSnapshot

    public let dimensions: GameboardDimensions = .cube4
    fileprivate var markers: [Location: PlayerMarker] = .empty

    public init() {}

    public func marker(at location: Location) -> PlayerMarker? {
        markers[location]
    }

    public mutating func markPlayer(_ mark: PlayerMarker, at location: Location) {
        markers[location] = mark
    }

    public func snapshot(with currentTurn: PlayerMarker?) -> Snapshot {
        Snapshot(markers: markers, currentTurn: currentTurn)
    }

    public var description: String {
        func text(_ vPos: VerticalFourPosition, _ hPos: HorizontalFourPosition, _ zPos: DepthFourPosition) -> String {
            let location = Location(vPos, hPos, zPos)
            return markers[location].map(\.description) ?? " "
        }

        let hLine = "-----"
        let rows = VerticalFourPosition.allCases.map { vPos in
            DepthFourPosition.allCases.reduce(into: String.empty) { result, zPos in
                let boardRow = HorizontalFourPosition.allCases.map { hPos in
                    "\(text(vPos, hPos, zPos))|\(text(vPos, hPos, zPos))|\(text(vPos, hPos, zPos))"
                }
                result += boardRow.joined(separator: "   ")
            }
        }
        let boardRows = rows.joined(separator: "\(hLine)   \(hLine)   \(hLine)\n")
        return "\(boardRows)\n"
    }

    public static func locations(for winningLine: WinningLine) -> Set<Location> {
        switch winningLine {
        case .horizontal(let yPos, let zPos):
            HorizontalFourPosition.allCases.reduce(into: .empty) { $0.insert(.init(yPos, $1, zPos)) }
        case .vertical(let xPos, let zPos):
            VerticalFourPosition.allCases.reduce(into: .empty) { $0.insert(.init($1, xPos, zPos)) }
        case .depth(let xPos, let yPos):
            DepthFourPosition.allCases.reduce(into: .empty) { $0.insert(.init(yPos, xPos, $1)) }
        case .zDiagonal(let zPos, let isBackslash):
            Set(
                zip(
                    VerticalFourPosition.allCases,
                    isBackslash ? HorizontalFourPosition.allCases : HorizontalFourPosition.allCases.reversed()
                )
                .map { (yPos, xPos) in Location(yPos, xPos, zPos) }
            )
        case .yDiagonal(let yPos, let isBackslash):
            Set(
                zip(
                    DepthFourPosition.allCases,
                    isBackslash ? HorizontalFourPosition.allCases.reversed() : HorizontalFourPosition.allCases
                )
                .map { (zPos, xPos) in Location(yPos, xPos, zPos) }
            )
        case .xDiagonal(let xPos, let isBackslash):
            Set(
                zip(
                    DepthFourPosition.allCases,
                    isBackslash ? VerticalFourPosition.allCases : VerticalFourPosition.allCases.reversed()
                )
                .map { (zPos, yPos) in Location(yPos, xPos, zPos) }
            )
        case .crossDiagonal(let isFront, let isBackslash):
            Set(
                zip(
                    HorizontalFourPosition.allCases,
                    zip(
                        isBackslash ? VerticalFourPosition.allCases : VerticalFourPosition.allCases.reversed(),
                        isFront ? DepthFourPosition.allCases : DepthFourPosition.allCases.reversed()
                    )
                )
                .map { (xPos, yzPos) in Location(yzPos.0, xPos, yzPos.1) }
            )
        }
    }
}

public struct CubeFourGameboardSnapshot: GameboardSnapshotProtocol {
    public typealias Location = CubeFourLocation
    public typealias WinningLine = CubeFourWinningLine

    public var dimensions: GameboardDimensions { .cube4 }
    fileprivate let markers: [Location: PlayerMarker]
    public let currentTurn: PlayerMarker?

    init(markers: [Location: PlayerMarker], currentTurn: PlayerMarker?) {
        self.markers = markers
        self.currentTurn = currentTurn
    }

    public func marker(at location: Location) -> PlayerMarker? {
        markers[location]
    }

    public var description: String {
        .empty
    }

    public static func locations(for winningLine: WinningLine) -> Set<Location> {
        CubeFourGameboard.locations(for: winningLine)
    }
}
