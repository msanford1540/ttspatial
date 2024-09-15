//
//  RealityRotateViewModifier.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/29/24.
//

import SwiftUI
import RealityKit

public struct RealityRotateViewModifier: ViewModifier {
    @State private var baseRotation: simd_quatf?
    private let targetEntity: Entity
    private let onChangeAction: ((simd_quatf) -> Void)?

    init(targetEntity: Entity, onChangeAction: ((simd_quatf) -> Void)? = nil) {
        self.targetEntity = targetEntity
        self.onChangeAction = onChangeAction
    }

    public func body(content: Content) -> some View {
#if os(visionOS)
        visionOSBody(content: content)
#else
        generalOSBody(content: content)
#endif
    }

#if os(visionOS)
    private func visionOSBody(content: Content) -> some View {
        content
            .gesture(
                RotateGesture3D() // two-handed rotation gesture
                    .targetedToEntity(targetEntity)
                    .onChanged { value in
                        if baseRotation == nil {
                            baseRotation = targetEntity.transform.rotation
                        }
                        guard let baseRotation else { return }
                        let rotation = value.rotation
                        // swap from SwiftUI coordinate system to RealityKit;
                        // code thanks to
                        // https://developer.apple.com/documentation/realitykit/transforming-realitykit-entities-with-gestures
                        let flippedRotation = simd_quatf(
                            angle: Float(rotation.angle.radians),
                            axis: .init(
                                x: Float(-rotation.axis.x),
                                y: Float(rotation.axis.y),
                                z: Float(-rotation.axis.z)
                            )
                        )
                        let newOrientation = flippedRotation * baseRotation
                        targetEntity.transform.rotation = newOrientation
                        onChangeAction?(newOrientation)
                    }
                    .onEnded { _ in
                        baseRotation = nil
                    }
                    .simultaneously(with: DragGesture() // one-handed custom rotation gesture
                        .targetedToEntity(targetEntity)
                        .onChanged { value in
                            if baseRotation == nil {
                                baseRotation = targetEntity.transform.rotation
                            }
                            guard let baseRotation else { return }
                            // from https://developer.apple.com/documentation/visionos/world
                            let location3D = value.convert(value.location3D, from: .local, to: .scene)
                            let startLocation3D = value.convert(value.startLocation3D, from: .local, to: .scene)
                            let delta = location3D - startLocation3D

                            // inspired by https://stackoverflow.com/a/76823868
                            // similar to above, we want to adjust the coordinate system
                            let transformAngles = Transform(
                                pitch: atan(-delta.y) * .pi,
                                yaw: atan(delta.x) * .pi
                            )
                            let newOrientation = transformAngles.rotation * baseRotation
                            targetEntity.transform.rotation = newOrientation
                            onChangeAction?(newOrientation)
                        }
                        .onEnded { _ in
                            baseRotation = nil
                        }
                    )
            )
    }
#else
    func generalOSBody(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if baseRotation == nil {
                            baseRotation = targetEntity.transform.rotation
                        }
                        guard let baseRotation else { return }
                        let rotation = simd_quatf(translation: value.translation)
                        let newOrientation = rotation * baseRotation
                        targetEntity.transform.rotation = newOrientation
                    }
                    .onEnded { _ in
                        baseRotation = nil
                    }
            )
    }
#endif
}

public extension View {
    func addRotateGestures(to entity: Entity, action: ((simd_quatf) -> Void)? = nil) -> some View {
        modifier(RealityRotateViewModifier(targetEntity: entity))
    }
}

private extension simd_quatf {
    init(translation: CGSize) {
        // Calculate rotation angle
        let hypot = hypot(translation.width, translation.height)
        let rotation = Angle(degrees: hypot)
        // Calculate rotation axis
        let axisX = Float(translation.height / hypot)
        let axisY = Float(translation.width / hypot)
        let rotationAxis = SIMD3<Float>(x: axisX, y: axisY, z: .zero)
        let sensitivityFactor: Float = 0.333
        self.init(angle: Float(rotation.radians) * sensitivityFactor, axis: rotationAxis)
    }
}
