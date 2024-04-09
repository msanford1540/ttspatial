//
//  Gameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import RealityKit
import Combine

struct Gameboard: View {
    private class Entities {
        private(set) var places: Entity = .empty
        private(set) var xTemplateEntity: Entity = .empty
        private(set) var oTemplateEntity: Entity = .empty
        private(set) var lineTemplateEntity: Entity = .empty

        func setup(scene: Entity) {
            guard let places = scene.findEntity(named: "places"),
                  let xEntity = scene.findEntity(named: "marker_x"),
                  let oEntity = scene.findEntity(named: "marker_o"),
                  let lineEntity = scene.findEntity(named: "line_horizontal") else {
                fatalError("invalid scene")
            }
            
            self.places = places
            xTemplateEntity = xEntity
            xTemplateEntity.isEnabled = false
            oTemplateEntity = oEntity
            oTemplateEntity.isEnabled = false
            lineTemplateEntity = lineEntity
            lineTemplateEntity.isEnabled = false
        }
    }

    private class GameboardState {
        var xEntities: [GridLocation: Entity] = .empty
        var oEntities: [GridLocation: Entity] = .empty
        var lineEntities: [WinningLine: Entity] = .empty
        var blankEntities: [GridLocation: Entity] = .empty

        var snapsnot: GameSnapshot {
            var cellStates: [GridLocation: GameSnapshot.GridCellState] = .empty
            for location in GridLocation.allCases {
                if xEntities[location] != nil {
                    cellStates[location] = .marked(.x)
                } else if oEntities[location] != nil {
                    cellStates[location] = .marked(.o)
                } else if let entity = blankEntities[location] {
                    cellStates[location] = .unmarked(entity.isEnabled)
                } else {
                    assertionFailure("unexpected gameboard state")
                }
            }
            assert(cellStates.count == GridLocation.allCases.count)
            return .init(cells: cellStates, winningLines: Set(lineEntities.keys))
        }
    }

    private func stateChanges(from: GameSnapshot, to: GameSnapshot) -> [StateChange] {
        assert(from.cells.count == GridLocation.allCases.count)
        assert(to.cells.count == GridLocation.allCases.count)

        let addLines = to.winningLines.subtracting(from.winningLines).map(StateChange.addWinningLine)
        let removeLines = from.winningLines.subtracting(to.winningLines).map(StateChange.removeWinningLine)
        let cellChanges: [StateChange] = GridLocation.allCases.reduce(into: .empty) { result, location in
            guard let fromState = from.cells[location], let toState = to.cells[location] else {
                assertionFailure("missing state")
                return
            }
            if fromState != toState {
                result.append(.changeCell(location, from: fromState, to: toState))
            }
        }
        return addLines + removeLines + cellChanges
    }

    private enum StateChange: CustomStringConvertible {
        case addWinningLine(WinningLine)
        case removeWinningLine(WinningLine)
        case changeCell(GridLocation, from: GameSnapshot.GridCellState, to: GameSnapshot.GridCellState)
    
        var description: String {
            switch self {
            case .addWinningLine(let winningLine): "[add line: \(winningLine)]"
            case .removeWinningLine(let winningLine): "[remove line: \(winningLine)]"
            case .changeCell(let location, let from, let to): "[change cell: [\(location)] \(from) -> \(to)]"
            }
        }
    }

    @EnvironmentObject var gameEngine: GameEngine
    private let entities = Entities()
    private let state = GameboardState()

    var body: some View {
        RealityView { content, attachments in
            guard let scene = try? await Entity(named: "Scene", in: .main) else { return }
            content.add(scene)
            entities.setup(scene: scene)

            GridLocation.allCases.forEach { location in
                scene.findEntity(named: location.name).map {
                    $0.components.set([
                        HoverEffectComponent(),
                        location
                    ])
                    state.blankEntities[location] = $0
                }
            }

            if let controlsAttachment = attachments.entity(for: "controls") {
                controlsAttachment.position = [0, -0.55, 0]
                scene.addChild(controlsAttachment)
            }
        } update: { _, _  in
            let changes = stateChanges(from: state.snapsnot, to: gameEngine.snapshot)
            print("changes: \(changes)")
            updateChanges(changes)
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "controls") {
                Dashboard()
                    .environmentObject(GameSession.shared)
            }
        }
        .gesture(TapGesture().targetedToAnyEntity()
            .onEnded { value in
                guard let location = value.entity.components[GridLocation.self] else { return }
                gameEngine.mark(at: location)
            }
        )
    }

    private func updateChanges(_ changes: [StateChange]) {
        for change in changes {
            switch change {
            case .addWinningLine(let line):
                addWinningLine(line)
            case .removeWinningLine(let line):
                removeWinningLine(line)
            case .changeCell(let location, let from, let to):
                changeCell(at: location, from: from, to: to)
            }
        }
    }

    private func changeCell(at location: GridLocation, from: GameSnapshot.GridCellState, to: GameSnapshot.GridCellState) {
        switch (from, to) {
        case (.unmarked(true), .marked(let mark)):
            addMark(mark, at: location)
        case (.unmarked(false), .unmarked(true)):
            enableUnmarkedCell(at: location)
        case (.unmarked(true), .unmarked(false)):
            disableUnmarkedCell(at: location)
        case (.marked(let mark), .unmarked(true)):
            removeMark(mark, at: location)
        default:
            assertionFailure("change type not supported. from: \(from), to: \(to)")
        }
    }

    private func removeMark(_ mark: PlayerMarker, at location: GridLocation) {
        let entity: Entity?
        switch mark {
        case .x:
            entity = state.xEntities[location]
            state.xEntities[location] = nil
        case .o:
            entity = state.oEntities[location]
            state.oEntities[location] = nil
        }
        guard let entity else { return }
        entity.animateOpacity(to: .zero, duration: .removeDuration) {
            entity.removeFromParent()
        }
        state.blankEntities[location]?.isEnabled = true
    }
    
    private func enableUnmarkedCell(at location: GridLocation) {
        guard let entity = state.blankEntities[location] else {
            assertionFailure("expected entity")
            return
        }
        entity.isEnabled = true
    }
    
    private func disableUnmarkedCell(at location: GridLocation) {
        guard let entity = state.blankEntities[location] else {
            assertionFailure("expected entity")
            return
        }
        entity.isEnabled = false
    }
    
    private func addMark(_ mark: PlayerMarker, at location: GridLocation) {
        guard let blankEntity = state.blankEntities[location] else {
            assertionFailure("expected entity")
            return
        }
        let postion = blankEntity.position
        blankEntity.isEnabled = false
        let templateEntity = templateEntity(for: mark)
        let markedEntity = templateEntity.clone(recursive: true)
        markedEntity.position = postion
        markedEntity.isEnabled = true
        markedEntity.components.set([
            HoverEffectComponent(),
            OpacityComponent(opacity: 0)
        ])
        entities.places.addChild(markedEntity)
        markedEntity.animateOpacity(to: 1, duration: .markDuration)
        switch mark {
        case .x: state.xEntities[location] = markedEntity
        case .o: state.oEntities[location] = markedEntity
        }
    }
    
    private func addWinningLine(_ line: WinningLine) {
        let rowOffset: Float = 0.30
        guard state.lineEntities[line] == nil else {
            assertionFailure("expected entity")
            return
        }
        let xRotationDegrees: Float
        let scale: Float
        var position: SIMD3<Float> = .init(x: 0, y: 0, z: 0.05)
        switch line {
        case .horizontal(let verticalPosition):
            xRotationDegrees = 0
            scale = 1.15
            switch verticalPosition {
            case .top: position.y = rowOffset
            case .middle: break
            case .bottom: position.y = -rowOffset
            }
        case .vertical(let horizontalPosition):
            xRotationDegrees = 90
            scale = 1.15
            switch horizontalPosition {
            case .left: position.x = -rowOffset
            case .middle: break
            case .right: position.x = rowOffset
            }
        case .diagonal(let isBackslash):
            xRotationDegrees = isBackslash ? 45 : 135
            scale = 1.33
        }
        let newLine = entities.lineTemplateEntity.clone(recursive: true)
        newLine.isEnabled = true
        newLine.position = position
        newLine.transform.scale = .init(x: 1, y: 1, z: 0)
        newLine.transform.setRotationAngles(xRotationDegrees, 90, 0)
        state.lineEntities[line] = newLine
        entities.places.parent?.addChild(newLine)
        newLine.animateScale(to: .init(x: 1, y: 1, z: scale), duration: .drawLineDuration)
    }

    private func removeWinningLine(_ line: WinningLine) {
        guard let entity = state.lineEntities[line] else {
            assertionFailure("expected entity")
            return
        }
        entity.animateOpacity(to: 0, duration: .removeDuration) {
            entity.removeFromParent()
        }
        state.lineEntities[line] = nil
    }

    private func templateEntity(for marker: PlayerMarker) -> Entity {
        switch marker {
        case .x: return entities.xTemplateEntity
        case .o: return entities.oTemplateEntity
        }
    }
}

#Preview(windowStyle: .volumetric) {
    Gameboard()
}

private extension Entity {
    static let empty: Entity = .init()

    var childrenCopy: [Entity] {
        children.reduce(into: []) { result, child in result.append(child) }
    }
}

extension GridLocation: Component {}

private extension GridLocation {
    var name: String {
        x == .middle && y == .middle
            ? x.name
            : "\(y.name)_\(x.name)"
    }
}

private extension GridLocation.HorizontalPosition {
    var name: String {
        switch self {
        case .left: return "left"
        case .middle: return "middle"
        case .right: return "right"
        }
    }
}

private extension GridLocation.VerticalPosition {
    var name: String {
        switch self {
        case .top: return "top"
        case .middle: return "middle"
        case .bottom: return "bottom"
        }
    }
}

private func deg2rad<FloatType: BinaryFloatingPoint>(_ degrees: FloatType) -> FloatType {
    degrees * FloatType.pi / 180
}

private extension Transform {
    mutating func setRotationAngles(_ xDegrees: Float, _ yDegrees: Float, _ zDegrees: Float) {
        let xRotation = simd_quatf(angle: deg2rad(xDegrees), axis: .init(x: 1, y: 0, z: 0))
        let yRotation = simd_quatf(angle: deg2rad(yDegrees), axis: .init(x: 0, y: 1, z: 0))
        let zRotation = simd_quatf(angle: deg2rad(zDegrees), axis: .init(x: 0, y: 0, z: 1))
        self.rotation = zRotation * yRotation * xRotation
    }
}

private extension Entity {
    func animateScale(to scale: SIMD3<Float>, duration: TimeInterval = 1.0, completion: (@Sendable () -> Void)? = nil) {
        var transform = self.transform
        transform.scale = scale
        if let animation = try? AnimationResource.generate(
            with: FromToByAnimation(to: transform, duration: duration, bindTarget: .transform)
        ) {
            playAnimation(animation)
            if let completion {
                Task {
                    try await Task.sleep(nanoseconds: .init(duration * 1_000_000_000))
                    completion()
                }
            }
        } else {
            self.transform = transform
            completion?()
        }
    }

    func animateOpacity(to opacity: Float, duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        let fromOpacity: Float?
        if let opacityComponent = components[OpacityComponent.self] {
            fromOpacity = opacityComponent.opacity
        } else {
            fromOpacity = nil
        }
        if let animation = try? AnimationResource.generate(
            with: FromToByAnimation(from: fromOpacity, to: opacity, duration: duration, bindTarget: .opacity)
        ) {
            playAnimation(animation)
            if let completion {
                Task {
                    try await Task.sleep(nanoseconds: .init(duration * 1_000_000_000))
                    completion()
                }
            }
        } else {
            components.set(OpacityComponent(opacity: opacity))
            completion?()
        }
    }
}

private extension TimeInterval {
    static let removeDuration: TimeInterval = 0.5
    static let markDuration: TimeInterval = 0.25
    static let drawLineDuration: TimeInterval = 0.5
}
