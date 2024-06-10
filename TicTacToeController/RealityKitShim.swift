//
//  RealityKitShim.swift
//  TicTacToeController
//
//  Created by Mike Sanford (1540) on 5/31/24.
//

import RealityKit

public protocol RealityKitShim {
    var minInputOpacity: Float { get }
    @MainActor func animate(entity: Entity, toOpacity opacity: Float, duration: Duration) async
}

private let defaultDuration: Duration = .seconds(1)

public extension RealityKitShim {
    @MainActor func animate(entity: Entity, toOpacity opacity: Float) async {
        await animate(entity: entity, toOpacity: opacity, duration: defaultDuration)
    }

    @MainActor func animateToMinInputOpacity(entity: Entity, duration: Duration) async {
        await animate(entity: entity, toOpacity: minInputOpacity, duration: duration)
    }

    @MainActor func animateToMinInputOpacity(entity: Entity) async {
        await animate(entity: entity, toOpacity: minInputOpacity, duration: defaultDuration)
    }
}

private var unsafeRealityKitShim: RealityKitShim?
var realityKitShim: RealityKitShim {
    guard let unsafeRealityKitShim else {
        fatalError("attempt to access uninitialized shim")
    }
    return unsafeRealityKitShim
}

public func setRealityKitShim(_ shim: RealityKitShim) {
    unsafeRealityKitShim = shim
}

public extension Entity {
    @MainActor func animateOpacity(to opacity: Float, duration: Duration) async {
        await realityKitShim.animate(entity: self, toOpacity: opacity, duration: duration)
    }

    @MainActor func animateToMinInputOpacity(duration: Duration) async {
        await realityKitShim.animateToMinInputOpacity(entity: self, duration: duration)
    }

    @MainActor func animateToMinInputOpacity() async {
        await realityKitShim.animateToMinInputOpacity(entity: self)
    }
}
