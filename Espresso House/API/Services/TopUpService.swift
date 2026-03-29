//
//  TopUpService.swift
//  Espresso House
//

import Foundation

class TopUpService: TopUpServiceProtocol {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func getTopUpValues() async throws -> [TopUpValue] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let data = try await networkManager.requestData(endpoint: Endpoint.getTopUpValues(memberId: memberId))
        let decoder = JSONDecoder()

        // Try as wrapped response first, then as plain array
        if let response = try? decoder.decode(TopUpValuesResponse.self, from: data),
           let values = response.topUpValues {
            return values
        }
        if let values = try? decoder.decode([TopUpValue].self, from: data) {
            return values
        }
        return []
    }

    func getTopUpPaymentMethods() async throws -> [TopUpPaymentMethod] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let data = try await networkManager.requestData(endpoint: Endpoint.getTopUpPaymentOptions(memberId: memberId))
        let decoder = JSONDecoder()

        if let response = try? decoder.decode(TopUpPaymentOptionsResponse.self, from: data),
           let options = response.paymentOptions {
            return options
        }
        if let options = try? decoder.decode([TopUpPaymentMethod].self, from: data) {
            return options
        }
        return []
    }

    func topUpWithCreditCard(paymentTokenKey: String, currencyCode: String, amount: Double) async throws {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let request = TopUpCreditCardRequest(
            paymentTokenKey: paymentTokenKey,
            currencyCode: currencyCode,
            amount: amount
        )
        try await networkManager.postRaw(
            endpoint: Endpoint.topUpCreditCard(memberId: memberId),
            body: request,
            authenticated: true
        )
    }

    func topUpWithSwish(currencyCode: String, amount: Double) async throws -> String {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let request = TopUpSwishRequest(currencyCode: currencyCode, amount: amount)
        let response: TopUpSwishResponse = try await networkManager.post(
            endpoint: Endpoint.topUpSwish(memberId: memberId),
            body: request,
            authenticated: true
        )
        return response.swishPaymentRequestToken
    }

    func getDirectPaymentMethods() async throws -> [DirectPaymentMethod] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        // Same endpoint as getTopUpPaymentMethods but decoded as DirectPaymentMethod
        let data = try await networkManager.requestData(endpoint: Endpoint.getTopUpPaymentOptions(memberId: memberId))
        let decoder = JSONDecoder()

        struct Wrapped: Decodable {
            let topUpPaymentOptions: [DirectPaymentMethod]?
            let paymentOptions: [DirectPaymentMethod]?
        }
        if let wrapped = try? decoder.decode(Wrapped.self, from: data),
           let methods = wrapped.topUpPaymentOptions ?? wrapped.paymentOptions {
            return methods
        }
        if let methods = try? decoder.decode([DirectPaymentMethod].self, from: data) {
            return methods
        }
        return []
    }

    func createDirectPayment(request: StartDirectPaymentRequest) async throws -> StartDirectPaymentResponse {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }

        // Log raw request and response for debugging
        let encoder = JSONEncoder()
        if let reqData = try? encoder.encode(request),
           let reqStr = String(data: reqData, encoding: .utf8) {
            print("[DirectPayment] Request body: \(reqStr)")
        }

        let data = try await networkManager.postReturningData(
            endpoint: Endpoint.createDirectPayment(memberId: memberId),
            body: request,
            authenticated: true
        )
        let raw = String(data: data.prefix(2000), encoding: .utf8) ?? ""
        print("[DirectPayment] Response body: \(raw)")
        return try JSONDecoder().decode(StartDirectPaymentResponse.self, from: data)
    }

    func getPaymentTransactionStatus(transactionKey: String) async throws -> PaymentTransactionResponse {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        return try await networkManager.request(
            endpoint: Endpoint.getPaymentTransaction(memberId: memberId, transactionKey: transactionKey)
        )
    }

    func getMemberEvents() async throws -> [MemberEvent] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let data = try await networkManager.requestData(endpoint: Endpoint.getMemberEvents(memberId: memberId))

        let decoder = JSONDecoder()
        if let response = try? decoder.decode(MemberEventsResponse.self, from: data),
           let events = response.events, !events.isEmpty {
            return events
        }
        if let events = try? decoder.decode([MemberEvent].self, from: data), !events.isEmpty {
            return events
        }

        // Last resort: manual JSON parsing to never lose an event
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let eventsArray = json["events"] as? [[String: Any]], !eventsArray.isEmpty {
            let parsed = eventsArray.compactMap { dict -> MemberEvent? in
                guard let name = (dict["eventName"] as? String) ?? (dict["eventType"] as? String) else { return nil }
                return MemberEvent(
                    eventType: name,
                    myEspressoHouseNumber: dict["myEspressoHouseNumber"] as? String,
                    eventData: dict["eventData"] as? String,
                    created: dict["created"] as? String
                )
            }
            if !parsed.isEmpty {
                return parsed
            }
        }

        return []
    }
}
