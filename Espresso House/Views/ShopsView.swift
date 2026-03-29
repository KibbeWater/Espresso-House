//
//  ShopsView.swift
//  Espresso House
//
//  Created by KibbeWater on 19/12/24.
//

import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct ShopMapView: View {
    @State private var shopPopover = false

    let location: CoffeeShop
    let onNavigate: () -> Bool

    private var canOrder: Bool {
        location.isCurrentlyOpen && location.preorderOnline
    }

    private var statusText: String {
        if !location.preorderOnline { return "No online ordering" }
        if location.isClosedToday { return "Closed today" }
        if !location.isCurrentlyOpen { return "Closed" }
        return "Open"
    }

    var body: some View {
        Image("ShopMarker")
            .opacity(canOrder ? 1.0 : 0.4)
            .onTapGesture {
                withAnimation {
                    shopPopover.toggle()
                }
            }
            .popover(isPresented: $shopPopover) {
                Button {
                    if canOrder {
                        if onNavigate() {
                            shopPopover = false
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.name)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(canOrder ? .green : .red)
                                    .frame(width: 7, height: 7)
                                Text(statusText)
                                    .foregroundStyle(canOrder ? .green : .red)
                                    .fontWeight(.medium)
                                if location.preorderOnline {
                                    Text(location.formattedHours)
                                }
                            }
                            .font(.caption)
                        }

                        if canOrder {
                            Image(systemName: "chevron.right")
                                .imageScale(.medium)
                        }
                    }
                    .foregroundStyle(.primary)
                    .padding(12)
                    .presentationCompactAdaptation(.popover)
                }
                .disabled(!canOrder)
            }
    }
}

struct ShopsView: View {
    @Environment(\.espressoAPI) private var api
    @State private var shops: [CoffeeShop] = []

    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic

    @State private var showOrderingView: Bool = false
    @State private var selectedShop: CoffeeShop?

    @State private var searchText: String = ""

    @Environment(\.activeOrderVM) private var activeOrderVM

    private let radiusInKm: Double = 5.0

    private var nearbyLocations: [CoffeeShop] {
        guard let userLocation = locationManager.userLocation else { return [] }
        return shops.filter { location in
            let distance = calculateDistance(from: userLocation, to: location.location)
            return distance <= radiusInKm
        }
    }

    /// Shops sorted by distance, filtered by search text
    private var filteredShops: [CoffeeShop] {
        let sorted: [CoffeeShop]
        if let userLocation = locationManager.userLocation {
            sorted = shops.sorted {
                calculateDistance(from: userLocation, to: $0.location) <
                calculateDistance(from: userLocation, to: $1.location)
            }
        } else {
            sorted = shops
        }

        if searchText.isEmpty { return sorted }
        let query = searchText.lowercased()
        return sorted.filter {
            $0.name.lowercased().contains(query) || $0.city.lowercased().contains(query)
        }
    }

    private func distanceText(to shop: CoffeeShop) -> String? {
        guard let userLocation = locationManager.userLocation else { return nil }
        let km = calculateDistance(from: userLocation, to: shop.location)
        let usesMetric = Locale.current.measurementSystem == .metric
        if usesMetric {
            if km < 1 {
                return "\(Int(km * 1000)) m"
            }
            return String(format: "%.1f km", km)
        } else {
            let miles = km * 0.621371
            if miles < 0.1 {
                let feet = Int(miles * 5280)
                return "\(feet) ft"
            }
            return String(format: "%.1f mi", miles)
        }
    }

    private var optimalRegion: MKCoordinateRegion {
        guard let userLocation = locationManager.userLocation else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        var coordinates = [userLocation]
        coordinates.append(contentsOf: nearbyLocations.map { $0.location })

        if let closestLocation = findClosestLocation() {
            coordinates.append(closestLocation.location)
        }

        return calculateOptimalRegion(for: coordinates)
    }

    func fetchShops() {
        Task {
            shops = (try? await api.shop.getShops()) ?? []
        }
    }

    private func zoomToShop(_ shop: CoffeeShop) {
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(MKCoordinateRegion(
                center: shop.location,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                UserAnnotation()
                ForEach(shops) { shop in
                    Annotation(shop.name, coordinate: shop.location, anchor: .bottom) {
                        ShopMapView(location: shop) {
                            selectedShop = shop
                            showOrderingView = true
                            return true
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .ignoresSafeArea(edges: .top)

            // Shop list sheet (always visible)
            ShopListSheet(
                shops: filteredShops,
                searchText: $searchText,
                distanceText: distanceText,
                onSelectShop: { shop in
                    selectedShop = shop
                    zoomToShop(shop)
                },
                onOrderFromShop: { shop in
                    selectedShop = shop
                    showOrderingView = true
                }
            )
        }
        .navigationDestination(isPresented: $showOrderingView) {
            if let selectedShop {
                OrderView(selectedShop)
            }
        }
        .onChange(of: shops) { _, _ in
            withAnimation {
                position = .region(optimalRegion)
            }
        }
        .onAppear {
            fetchShops()
        }
    }

    private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2) / 1000
    }

    private func findClosestLocation() -> CoffeeShop? {
        guard let userLocation = locationManager.userLocation else { return nil }
        return shops.min { location1, location2 in
            let distance1 = calculateDistance(from: userLocation, to: location1.location)
            let distance2 = calculateDistance(from: userLocation, to: location2.location)
            return distance1 < distance2
        }
    }

    private func calculateOptimalRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: coordinates.first ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLong = coordinates.map { $0.longitude }.min() ?? 0
        let maxLong = coordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLong + maxLong) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLong - minLong) * 1.5
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Shop List Sheet

struct ShopListSheet: View {
    let shops: [CoffeeShop]
    @Binding var searchText: String
    let distanceText: (CoffeeShop) -> String?
    let onSelectShop: (CoffeeShop) -> Void
    let onOrderFromShop: (CoffeeShop) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search shops...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray5).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Shop list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(shops) { shop in
                        let canOrder = shop.isCurrentlyOpen && shop.preorderOnline
                        Button {
                            if canOrder {
                                onSelectShop(shop)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(shop.name)
                                        .fontWeight(.medium)
                                        .foregroundStyle(canOrder ? .primary : .tertiary)
                                        .lineLimit(1)

                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(canOrder ? .green : .red)
                                            .frame(width: 7, height: 7)
                                        if !shop.preorderOnline {
                                            Text("No online ordering")
                                                .foregroundStyle(.red)
                                        } else {
                                            Text(shop.isCurrentlyOpen ? "Open" : "Closed")
                                                .foregroundStyle(shop.isCurrentlyOpen ? .green : .red)
                                            Text(shop.formattedHours)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .font(.caption)

                                    if let addr = shop.address1, !addr.isEmpty {
                                        Text("\(addr), \(shop.city)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                if let dist = distanceText(shop) {
                                    Text(dist)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if canOrder {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        .disabled(!canOrder)

                        Divider()
                            .padding(.leading)
                    }
                }
            }
        }
        .frame(maxHeight: 260)
        .modifier(GlassBackgroundModifier())
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }
}

struct GlassBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(in: .rect(cornerRadius: 16))
        } else {
            content
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
}

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2) / 1000 // Convert to kilometers
    }
}

#Preview {
    ShopsView()
}
