//
//  RealityKitView.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 5/9/24.
//

import SwiftUI
import RealityKit
import UIKit
import ARKit
import TicTacToeController
import TicTacToeEngine
import Combine

@MainActor
struct RealityKitGridView: UIViewRepresentable {
    typealias Gameboard = GridGameboard
    fileprivate let controller: GameboardController2D
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession<Gameboard>
    @EnvironmentObject private var gameSession: GameSession<Gameboard>

    init(_ controller: GameboardController2D) {
        self.controller = controller
    }

    func makeUIView(context: Context) -> ARView {
        let view = context.coordinator.arView
        controller.setup(scene: context.coordinator.scene)
        context.coordinator.sharePlaySession = sharePlaySession
        context.coordinator.gameSession = gameSession
        view.cameraMode = .nonAR
        let camera = PerspectiveCamera()
        let cameraAnchor = AnchorEntity(world: .init(x: 0, y: 0, z: 1.1))
        cameraAnchor.addChild(camera)
        view.scene.addAnchor(cameraAnchor)
        let light = PointLight()
        light.light.intensity = 5000
        let lightAnchor = AnchorEntity(world: .init(x: 0, y: 0.1, z: 0.8))
        lightAnchor.addChild(light)
        view.scene.addAnchor(lightAnchor)

        view.automaticallyConfigureSession = false
        view.scene.addAnchor(context.coordinator.scene)
        if let skybox = try? EnvironmentResource.load(named: "cloudy-sky.hdr") {
            view.environment.sceneUnderstanding.options = [.receivesLighting, .occlusion, .collision]
            view.environment.lighting.resource = skybox
            view.environment.lighting.intensityExponent = -1
            view.environment.reverb = .preset(.cathedral)
            view.environment.background = .skybox(skybox)
        }
//        view.environment.background = .color(.systemBlue.withAlphaComponent(0.05))
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
    }

    func makeCoordinator() -> HitHelper {
        HitHelper()
    }

    private func setupAR(_ view: ARView) {
        // Start AR session
        let session = view.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.run(config)

        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        view.addSubview(coachingOverlay)

        // Set debug options
#if DEBUG
        view.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
#endif
    }
}

@MainActor
struct RealityKitCubeView: UIViewRepresentable {
    typealias Gameboard = CubeGameboard
    fileprivate let controller: GameboardController3D
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession<Gameboard>
    @EnvironmentObject private var gameSession: GameSession<Gameboard>

    init(_ controller: GameboardController3D) {
        self.controller = controller
    }

    func makeUIView(context: Context) -> ARView {
        let view = context.coordinator.arView
        controller.setup(scene: context.coordinator.scene)
        context.coordinator.sharePlaySession = sharePlaySession
        context.coordinator.gameSession = gameSession
        view.cameraMode = .nonAR
        let camera = PerspectiveCamera()
        let cameraAnchor = AnchorEntity(world: .init(x: 0, y: 0, z: 1.5))
        cameraAnchor.addChild(camera)
        view.scene.addAnchor(cameraAnchor)
        let light = PointLight()
        light.light.intensity = 5000
        let lightAnchor = AnchorEntity(world: .init(x: 0, y: 0.1, z: 0.8))
        lightAnchor.addChild(light)
        view.scene.addAnchor(lightAnchor)

        view.automaticallyConfigureSession = false
        view.scene.addAnchor(context.coordinator.scene)
        if let skybox = try? EnvironmentResource.load(named: "cloudy-sky.hdr") {
            view.environment.sceneUnderstanding.options = [.receivesLighting, .occlusion, .collision]
            view.environment.lighting.resource = skybox
            view.environment.lighting.intensityExponent = -1
            view.environment.reverb = .preset(.cathedral)
            view.environment.background = .skybox(skybox)
        }
//        view.environment.background = .color(.systemBlue.withAlphaComponent(0.05))
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
    }

    func makeCoordinator() -> CubeHitHelper {
        .init()
    }

    private func setupAR(_ view: ARView) {
        // Start AR session
        let session = view.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.run(config)

        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        view.addSubview(coachingOverlay)

        // Set debug options
#if DEBUG
        view.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
#endif
    }
}

@MainActor
final class HitHelper {
    let arView: ARView
    let scene: AnchorEntity
    fileprivate var sharePlaySession: SharePlayGameSession<GridGameboard>?
    fileprivate var gameSession: GameSession<GridGameboard>?
    fileprivate var subscribers: Set<AnyCancellable> = .empty

    init() {
        arView = ARView()
        guard let scene = try? Entity.loadAnchor(named: "Scene") else {
            fatalError("failed to load scene")
        }
        self.scene = scene
        setupLocations()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let hitLocation = sender.location(in: arView)
        guard let hitEntity = arView.entity(at: hitLocation) else {
            return
        }
        guard let cubeLocation = hitEntity.components[GridLocation.self] as? GridLocation else {
            return
        }
        sharePlaySession?.mark(at: cubeLocation)
    }

    func setupLocations() {
        for location in GridLocation.allCases {
            guard let entity = scene.findEntity(named: location.entityName) else { continue }
            let bounds = entity.visualBounds(relativeTo: nil)
            let size = bounds.extents
            let newEntity = Entity()
            newEntity.components.set([
                CollisionComponent(
                    shapes: [.generateBox(size: size)]
                ),
                ModelComponent(
                    mesh: .generateBox(size: size, cornerRadius: 0.0125),
                    materials: [SimpleMaterial(color: .gray.withAlphaComponent(.zero), isMetallic: false)]
                ),
                location
            ])
            newEntity.isEnabled = true
            newEntity.position = entity.position
            newEntity.name = entity.name
            entity.parent?.addChild(newEntity)
            entity.removeFromParent()
        }
    }
}

@MainActor
final class CubeHitHelper {
    let arView: ARView
    let scene: AnchorEntity
    fileprivate var sharePlaySession: SharePlayGameSession<CubeGameboard>?
    fileprivate var gameSession: GameSession<CubeGameboard>?
    fileprivate var subscribers: Set<AnyCancellable> = .empty

    init() {
        arView = ARView()
        guard let scene = try? Entity.loadAnchor(named: "Scene3D") else {
            fatalError("failed to load scene")
        }
        self.scene = scene
        setupLocations()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let hitLocation = sender.location(in: arView)
        guard let hitEntity = arView.entity(at: hitLocation) else {
            print("[debug] miss tap: \(hitLocation)")
            return
        }
        guard let cubeLocation = hitEntity.components[CubeLocation.self] as? CubeLocation else {
            return
        }
        sharePlaySession?.mark(at: cubeLocation)
    }

    func setupLocations() {
        for location in CubeLocation.allCases {
            guard let entity = scene.findEntity(named: location.entityName) else { continue }
            let bounds = entity.visualBounds(relativeTo: nil)
            let size = bounds.extents
            let newEntity = Entity()
            newEntity.components.set([
                CollisionComponent(
                    shapes: [.generateBox(size: size)]
                ),
                ModelComponent(
                    mesh: .generateBox(size: size, cornerRadius: 0.0125),
                    materials: [SimpleMaterial(color: .gray.withAlphaComponent(.zero), isMetallic: false)]
                ),
                location
            ])
            newEntity.isEnabled = true
            newEntity.position = entity.position
            newEntity.name = entity.name
            entity.parent?.addChild(newEntity)
            entity.removeFromParent()
        }
    }
}
