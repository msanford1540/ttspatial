//
//  RotationSender.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import GroupActivities
import simd
import OSLog

actor RotationSender {
    private let messenger: GroupSessionMessenger
    private let logger = Logger(category: "rotationSender")
    private var isThrottling: Bool = false
    private var mostRecentRotation: simd_quatf?

    init(messenger: GroupSessionMessenger) {
        self.messenger = messenger
    }

    func send(rotation: simd_quatf) {
        sendRotationThrottled(rotation)
    }

    private func sendRotationThrottled(_ rotation: simd_quatf) {
        mostRecentRotation = rotation
        guard !isThrottling else { return }
        isThrottling = true
        Task {
            try await Task.sleep(for: .milliseconds(33), tolerance: .milliseconds(3))
            if let mostRecentRotation {
                sendRotationNow(mostRecentRotation)
            }
            mostRecentRotation = nil
            isThrottling = false
        }
    }

    private func sendRotationNow(_ rotation: simd_quatf) {
        Task {
            let quanterion = Quanterion(rotation: rotation)
            do {
                logger.debug("send(rotation: \(rotation.debugDescription))")
                try await messenger.send(quanterion, to: .all)
            } catch {
                logger.error("[\(Self.self, privacy: .public)] failed to send rotation. error: \(error as NSError, privacy: .public)")
            }
        }
    }
}
