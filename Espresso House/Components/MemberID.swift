//
//  MemberID.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//

import SwiftUI
import PassKit
import CoreLocation

struct MemberID: View {
    @State private var showInfo = false

    let id: String
    var pinCode: String?
    var firstName: String?
    var lastName: String?

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var passInWallet = false
    @State private var generatedPass: PKPass?

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM h:mm:ss"
        return formatter.string(from: currentTime)
    }

    private var showAddToWallet: Bool {
        firstName != nil
    }

    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Text("Member ID")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showInfo.toggle()
                } label: {
                    HStack {
                        Text("info")
                        Image(systemName: "info.circle")
                    }
                }
                .sheet(isPresented: $showInfo) {
                    MemberIDInfoSheet()
                }
            }
            .padding(.horizontal)
            Barcode("\(id):member")
                .padding(.top, -8)
                .padding(.horizontal, 10)
            HStack {
                VStack(alignment: .leading) {
                    Text("Membership no:")
                    Text("\(id)")
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(formattedTime)
                        .monospacedDigit()
                        .onReceive(timer) { input in
                            currentTime = input
                        }

                    if let pinCode {
                        Text("Pin: \(pinCode)")
                    }
                }
            }
            .padding(.horizontal)

            if showAddToWallet, !passInWallet, let pass = generatedPass {
                AddPassToWalletButton([pass]) { added in
                    passInWallet = added
                }
                .addPassToWalletButtonStyle(.black)
                .frame(height: 44)
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        .padding(.vertical)
        .onAppear {
            if showAddToWallet {
                passInWallet = PassGenerator.isPassInWallet(memberId: id)
                fetchPass()
            }
        }
        .onChange(of: firstName) {
            fetchPass()
        }
    }

    private func fetchPass() {
        guard generatedPass == nil, !passInWallet, !id.isEmpty else { return }
        Task {
            let locations = await closestLocations()
            generatedPass = try? await PassGenerator.generatePass(
                memberId: id,
                firstName: firstName ?? "",
                lastName: lastName ?? "",
                pinCode: pinCode,
                locations: locations
            )
        }
    }

    private static let locationsKey = "cachedPassLocations"

    private func closestLocations() async -> [PassLocation] {
        guard let shops = try? await EspressoAPI.shared.shop.getShops() else {
            return Self.cachedLocations()
        }

        let locationManager = CLLocationManager()
        let results: [PassLocation]

        if let userLocation = locationManager.location {
            let sorted = shops.sorted { a, b in
                let distA = userLocation.distance(from: CLLocation(latitude: a.latitude, longitude: a.longitude))
                let distB = userLocation.distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
                return distA < distB
            }
            results = Array(sorted.prefix(10)).map {
                PassLocation(latitude: $0.latitude, longitude: $0.longitude, relevantText: $0.name)
            }
        } else {
            // No location — use cached if available, otherwise first 10
            let cached = Self.cachedLocations()
            if !cached.isEmpty {
                return cached
            }
            results = Array(shops.prefix(10)).map {
                PassLocation(latitude: $0.latitude, longitude: $0.longitude, relevantText: $0.name)
            }
        }

        // Cache for next time
        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: Self.locationsKey)
        }

        return results
    }

    private static func cachedLocations() -> [PassLocation] {
        guard let data = UserDefaults.standard.data(forKey: locationsKey),
              let locations = try? JSONDecoder().decode([PassLocation].self, from: data) else {
            return []
        }
        return locations
    }
}

#Preview {
    NavigationStack {
        VStack {
            MemberID(id: SharedVars.shared.memberId ?? "")
            Spacer()
            MemberID(id: SharedVars.shared.memberId ?? "")
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.secondary.opacity(0.3), lineWidth: 2)
                    )
                .padding(.horizontal)
        }
    }
}
