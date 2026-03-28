//
//  NetworkManager.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//


import Foundation
import Alamofire

class NetworkManager {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func buildHeaders(authenticated: Bool) -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json-patch+json",
            "Accept-Language": "en",
            "AppVersion": "3.9.91",
            "DeviceModel": "iPhone18,2",
            "DeviceType": "iPhone",
            "Latitude": "",
            "Longitude": "",
            "Manufacturer": "Apple",
            "OS": "iOS",
            "OSVersion": "26.3.1",
        ]

        if authenticated, let bpAuth = SharedVars.shared.bpAuth {
            headers.add(name: "BPAuth", value: bpAuth)
        }

        return headers
    }

    func request<T: Decodable>(endpoint: Endpoints) async throws -> T {
        print("[Network] GET \(endpoint.url)")
        let req = AF.request(endpoint.url, headers: buildHeaders(authenticated: true)).serializingDecodable(T.self)

        let res = await req.response
        let statusCode = res.response?.statusCode
        print("[Network] GET \(endpoint.url) – status: \(statusCode.map(String.init) ?? "nil")")

        switch res.result {
        case .success(let success):
            return success
        case .failure(let failure):
            if let data = res.data, let body = String(data: data, encoding: .utf8) {
                print("[Network] GET \(endpoint.url) – error body: \(body.prefix(2000))")
            }
            if failure.responseCode == 401 {
                throw EspressoAPIError.unauthorized
            }
            throw EspressoAPIError.internalError(description: failure.localizedDescription)
        }
    }

    func requestData(endpoint: Endpoints) async throws -> Data {
        print("[Network] GET (raw) \(endpoint.url)")
        let req = AF.request(endpoint.url, headers: buildHeaders(authenticated: true)).serializingData()
        let res = await req.response
        let statusCode = res.response?.statusCode
        print("[Network] GET (raw) \(endpoint.url) – status: \(statusCode.map(String.init) ?? "nil")")

        switch res.result {
        case .success(let data):
            return data
        case .failure(let failure):
            if failure.responseCode == 401 {
                throw EspressoAPIError.unauthorized
            }
            throw EspressoAPIError.internalError(description: failure.localizedDescription)
        }
    }

    func post<T: Decodable>(endpoint: Endpoints, body: some Encodable, authenticated: Bool = false) async throws -> T {
        let req = AF.request(
            endpoint.url,
            method: .post,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: buildHeaders(authenticated: authenticated)
        ).serializingDecodable(T.self)

        let res = await req.response

        switch res.result {
        case .success(let success):
            return success
        case .failure(let failure):
            if failure.responseCode == 401 {
                throw EspressoAPIError.unauthorized
            }
            throw EspressoAPIError.internalError(description: failure.localizedDescription)
        }
    }

    func put<T: Decodable>(endpoint: Endpoints, body: some Encodable, authenticated: Bool = false) async throws -> T {
        let req = AF.request(
            endpoint.url,
            method: .put,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: buildHeaders(authenticated: authenticated)
        ).serializingDecodable(T.self)

        let res = await req.response

        switch res.result {
        case .success(let success):
            return success
        case .failure(let failure):
            if failure.responseCode == 401 {
                throw EspressoAPIError.unauthorized
            }
            throw EspressoAPIError.internalError(description: failure.localizedDescription)
        }
    }

    func putRaw(endpoint: Endpoints, body: some Encodable, authenticated: Bool = false) async throws {
        let req = AF.request(
            endpoint.url,
            method: .put,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: buildHeaders(authenticated: authenticated)
        ).serializingData()

        let res = await req.response

        if let statusCode = res.response?.statusCode, statusCode == 200 {
            return
        }

        if let error = res.error {
            if error.responseCode == 401 {
                throw EspressoAPIError.unauthorized
            }
            throw EspressoAPIError.internalError(description: error.localizedDescription)
        }
    }

    func delete(endpoint: Endpoints, authenticated: Bool = true) async throws {
        let req = AF.request(
            endpoint.url,
            method: .delete,
            headers: buildHeaders(authenticated: authenticated)
        ).serializingData()

        let res = await req.response

        if let statusCode = res.response?.statusCode, (200...299).contains(statusCode) {
            return
        }

        if let error = res.error {
            if error.responseCode == 401 {
                throw EspressoAPIError.unauthorized
            }
            throw EspressoAPIError.internalError(description: error.localizedDescription)
        }
    }

    func postRaw(endpoint: Endpoints, body: some Encodable, authenticated: Bool = false) async throws {
        let req = AF.request(
            endpoint.url,
            method: .post,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: buildHeaders(authenticated: authenticated)
        ).serializingData()

        let res = await req.response

        if let statusCode = res.response?.statusCode, statusCode == 200 {
            return
        }

        if let error = res.error {
            if error.responseCode == 401 {
                throw EspressoAPIError.unauthorized
            }
            throw EspressoAPIError.internalError(description: error.localizedDescription)
        }
    }
}
