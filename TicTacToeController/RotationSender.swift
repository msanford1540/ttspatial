//
//  RotationSender.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import GroupActivities
import simd
import Combine
import OSLog

final class RotationSender: @unchecked Sendable {
    @Published var rotation: simd_quatf?
    private let messenger: GroupSessionMessenger
    private var subscriber: AnyCancellable?
    private let logger = Logger(category: "rotationSender")

    init(messenger: GroupSessionMessenger) {
        self.messenger = messenger
        self.subscriber = $rotation
            .throttle(for: .milliseconds(33), scheduler: ImmediateScheduler.shared, latest: true)
            .sink { [unowned self] rotation in
                guard let rotation else { return }
                send(rotation: rotation)
            }
    }

    private func send(rotation: simd_quatf) {
        Task {
            let quanterion = Quanterion(rotation: rotation)
            do {
                print("[debug]", "send(rotation: \(rotation))")
                try await messenger.send(quanterion, to: .all)
            } catch {
                logger.error("[\(Self.self, privacy: .public)] failed to send rotation. error: \(error as NSError, privacy: .public)")
            }
        }
    }
}
