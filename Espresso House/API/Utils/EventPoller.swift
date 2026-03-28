//
//  EventPoller.swift
//  Espresso House
//

import Foundation

class EventPoller {
    private let topUpService: TopUpServiceProtocol

    init(topUpService: TopUpServiceProtocol) {
        self.topUpService = topUpService
    }

    /// Polls member events matching the Android app's strategy:
    /// 50 max retries, 5s interval for first 36, then 30s interval.
    func pollForEvent(
        expectedType: String,
        failureTypes: [String] = [],
        maxRetries: Int = 50,
        shortDelayRetries: Int = 36,
        shortDelay: TimeInterval = 5,
        longDelay: TimeInterval = 30
    ) async throws -> MemberEvent {
        let expectedNormalized = normalize(expectedType)
        let failureNormalized = failureTypes.map { normalize($0) }

        print("[EventPoller] Starting poll for '\(expectedType)' (max \(maxRetries) retries)")

        for attempt in 1...maxRetries {
            try Task.checkCancellation()

            do {
                let events = try await topUpService.getMemberEvents()

                if !events.isEmpty {
                    let types = events.map { $0.eventType }
                    print("[EventPoller] Attempt \(attempt): events = \(types)")
                } else {
                    if attempt <= 3 || attempt % 10 == 0 {
                        print("[EventPoller] Attempt \(attempt): no events")
                    }
                }

                if let successEvent = events.first(where: {
                    normalize($0.eventType) == expectedNormalized
                }) {
                    print("[EventPoller] Matched success: \(successEvent.eventType)")
                    return successEvent
                }

                if let failEvent = events.first(where: {
                    failureNormalized.contains(normalize($0.eventType))
                }) {
                    print("[EventPoller] Matched failure: \(failEvent.eventType)")
                    throw EventPollerError.eventFailed(failEvent.eventType)
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as EventPollerError {
                throw error
            } catch {
                print("[EventPoller] Attempt \(attempt): fetch error: \(error.localizedDescription)")
            }

            let delay = attempt <= shortDelayRetries ? shortDelay : longDelay
            try await Task.sleep(for: .seconds(delay))
        }

        print("[EventPoller] Max retries exhausted")
        throw EventPollerError.timeout
    }

    private func normalize(_ s: String) -> String {
        s.uppercased().replacingOccurrences(of: "_", with: "")
    }
}

enum EventPollerError: LocalizedError {
    case timeout
    case eventFailed(String)

    var errorDescription: String? {
        switch self {
        case .timeout: return "Timed out waiting for event"
        case .eventFailed(let type): return "Event failed: \(type)"
        }
    }
}
