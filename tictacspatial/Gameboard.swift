//
//  Gameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import RealityKit
//import RealityKitContent
import Combine

struct Gameboard: View {
    private class GameboardState {
        var xEntities: [GridLocation: Entity] = [:]
        var oEntities: [GridLocation: Entity] = [:]
        var lineEntities: [WinningLine: Entity] = [:]
    }

    @EnvironmentObject var gameEngine: GameEngine
    @State var places: Entity?
    @State private var xTemplateEntity: Entity!
    @State private var oTemplateEntity: Entity!
    @State private var lineTemplateEntity: Entity!
    private let state = GameboardState()

    var body: some View {
        RealityView { content, attachments  in
            guard let scene = try? await Entity(named: "Scene", in: .main) else { return }
            content.add(scene)
            setup(scene: scene)
            if let controlsAttachment = attachments.entity(for: "controls") {
                controlsAttachment.position = [0, -0.55, 0]
                scene.addChild(controlsAttachment)
            }
        } update: { _, _  in
            guard let places else { return }
            places.childrenCopy.forEach { update($0) }
            updateWinningLines()
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "controls") {
                Button("Start Over") {
                    gameEngine.reset()
                }
                .font(.extraLargeTitle)
                .padding()
                .glassBackgroundEffect()
            }
        }
        .gesture(TapGesture().targetedToAnyEntity()
            .onEnded { value in
                guard let info = value.entity.components[GridLocationInfo.self] else { return }
                gameEngine.mark(at: info.location)
            }
        )
    }

    private func setup(scene: Entity) {
        places = scene.findEntity(named: "places")
        xTemplateEntity = scene.findEntity(named: "marker_x")
        xTemplateEntity.isEnabled = false
        oTemplateEntity = scene.findEntity(named: "marker_o")
        oTemplateEntity.isEnabled = false
        lineTemplateEntity = scene.findEntity(named: "line_horizontal")
        lineTemplateEntity.isEnabled = false
        GridLocation.allCases.forEach { gridLocation in
            scene.findEntity(named: gridLocation.name).map {
                $0.components.set([
                    HoverEffectComponent(),
                    GridLocationInfo(location: gridLocation, mark: nil)
                ])
            }
        }
    }

    private func update(_ entity: Entity) {
        guard let info = entity.components[GridLocationInfo.self] else { return }
        let location = info.location
        if let gameMark = gameEngine.marker(for: location) {
            // mark entity if not already
            if info.mark == gameMark {
                // this is the existing marked entity, so do nothing
                return
            }
            
            if info.mark == gameMark.opponent {
                // this marked to the opponent and should never happen, so do nothing
                assertionFailure("grid location mismarked. this should never happen")
                return
            }
            
            if let gameboardMark = marker(for: location) {
                // this is the blank entity, but already marked entity already exists, so do nothing
                assert(gameboardMark == gameMark)
                return
            }
            
            // mark new entity
            assert(info.mark == nil)
            markEntity(entity, with: gameMark)
        } else if gameEngine.isGameOver {
            entity.isEnabled = false
        } else if info.mark == nil {
            // gameboard is blank and gamestate is blank is ensure gameboard entity is enabled
            entity.isEnabled = true
        } else {
            // gamestate is blank, but not gameboard so remove it
            remove(entity, at: location)
        }
    }

    private func updateWinningLines() {
        guard let winningInfo = gameEngine.winningInfo else {
            if !state.lineEntities.isEmpty {
                state.lineEntities.values.forEach { $0.removeFromParent() }
                state.lineEntities.removeAll()
            }
            return
        }

        let rowOffset: Float = 0.30
        for line in winningInfo.lines {
            guard state.lineEntities[line] == nil else { return }
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
            let newLine = lineTemplateEntity.clone(recursive: true)
            newLine.isEnabled = true
            newLine.position = position
            newLine.transform.scale = .init(x: 1, y: 1, z: 0)
            newLine.transform.setRotationAngles(xRotationDegrees, 90, 0)
            state.lineEntities[line] = newLine
            places?.parent?.addChild(newLine)
            newLine.animateScale(to: .init(x: 1, y: 1, z: scale), duration: 0.5)
        }
    }

    private func markEntity(_ blankEntity: Entity, with mark: PlayerMarker) {
        guard let info = blankEntity.components[GridLocationInfo.self], info.mark == nil else { return }
        let location = info.location
        let postion = blankEntity.position
        blankEntity.isEnabled = false
        let templateEntity = templateEntity(for: mark)
        let markedEntity = templateEntity.clone(recursive: true)
        markedEntity.position = postion
        markedEntity.isEnabled = true
        let markedInfo = GridLocationInfo(location: location, mark: mark)
        markedEntity.components.set(markedInfo)
        places?.addChild(markedEntity)
        switch mark {
        case .x: state.xEntities[location] = markedEntity
        case .o: state.oEntities[location] = markedEntity
        }
    }
    
    private func remove(_ entity: Entity, at location: GridLocation) {
        guard let info = entity.components[GridLocationInfo.self] else { return }
        switch info.mark {
        case .none:
            assertionFailure("remove a blank entity should never happen")
            return
        case .x:
            state.xEntities[location] = nil
        case .o:
            state.oEntities[location] = nil
        }
        entity.removeFromParent()
    }

    private func marker(for location: GridLocation) -> PlayerMarker? {
        if state.xEntities[location] != nil { return .x }
        if state.oEntities[location] != nil { return .o }
        return nil
    }

    private func templateEntity(for marker: PlayerMarker) -> Entity {
        switch marker {
        case .x: return xTemplateEntity
        case .o: return oTemplateEntity
        }
    }
}

#Preview(windowStyle: .volumetric) {
    Gameboard()
}

private extension Entity {
    var childrenCopy: [Entity] {
        children.reduce(into: []) { result, child in result.append(child) }
    }
}

private struct GridLocationInfo: Component {
    let hover = HoverEffectComponent()
    let location: GridLocation
    let mark: PlayerMarker?
}

//extension GridLocation: Component {}

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
    func animateScale(to scale: SIMD3<Float>, duration: TimeInterval = 1.0) {
        var transform = self.transform
        transform.scale = scale
        if let animation = try? AnimationResource.generate(
            with: FromToByAnimation(to: transform, duration: duration, bindTarget: .transform)
        ) {
            playAnimation(animation)
        } else {
            self.transform = transform
        }
    }
}
