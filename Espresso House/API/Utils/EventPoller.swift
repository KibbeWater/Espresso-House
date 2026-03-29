//
//  EventPoller.swift
//  Espresso House
//

import Foundation

class EventPoller {
    private let topUpService: TopUpServiceProtocol
    private var nudgeContinuation: CheckedContinuation<Void, Never>?
    private let lock = NSLock()

    init(topUpService: TopUpServiceProtocol) {
        self.topUpService = topUpService
    }

    /// Signal the poller to check immediately.
    /// Called when the app is foregrounded via a callback URL.
    func nudge() {
        lock.lock()
        let continuation = nudgeContinuation
        nudgeContinuation = nil
        lock.unlock()
        continuation?.resume()
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

        for attempt in 1...maxRetries {
            try Task.checkCancellation()

            if let result = try await checkEvents(expectedNormalized: expectedNormalized, failureNormalized: failureNormalized) {
                return result
            }

            // Wait for the delay OR a nudge, whichever comes first
            let delay = attempt <= shortDelayRetries ? shortDelay : longDelay
            await waitOrNudge(seconds: delay)
        }

        throw EventPollerError.timeout
    }

    private func checkEvents(expectedNormalized: String, failureNormalized: [String]) async throws -> MemberEvent? {
        do {
            let events = try await topUpService.getMemberEvents()

            if let successEvent = events.first(where: {
                normalize($0.eventType) == expectedNormalized
            }) {
                return successEvent
            }

            if let failEvent = events.first(where: {
                failureNormalized.contains(normalize($0.eventType))
            }) {
                throw EventPollerError.eventFailed(failEvent.eventType)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as EventPollerError {
            throw error
        } catch {
            // Network error — continue polling
        }

        return nil
    }

    /// Sleeps for the given duration but wakes immediately if `nudge()` is called.
    private func waitOrNudge(seconds: TimeInterval) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.lock.withLock { nudgeContinuation = continuation }

            // Schedule a timer to resume after the delay if not nudged
            Task {
                try? await Task.sleep(for: .seconds(seconds))
                let pending = self.lock.withLock {
                    let c = self.nudgeContinuation
                    self.nudgeContinuation = nil
                    return c
                }
                pending?.resume()
            }
        }
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
