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
    
    var body: some View {
        Image("ShopMarker")
            .onTapGesture {
                withAnimation {
                    shopPopover.toggle()
                }
            }
            .popover(isPresented: $shopPopover) {
                Button {
                    if onNavigate() {
                        shopPopover = false
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(location.name)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Text("Open 07:00 - 21:00")
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(1)
                        }
                        .padding(.trailing)
                        VStack {
                            Image(systemName: "chevron.right")
                                .imageScale(.large)
                        }
                    }
                    .padding(12)
                    .presentationCompactAdaptation(.popover)
                }
            }
    }
}

struct ShopsView: View {
    @Environment(\.espressoAPI) private var api
    @State private var shops: [CoffeeShop] = []
    
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic
    @State private var region = MKCoordinateRegion()
    @State private var selectedLocation: CoffeeShop?
    
    @State private var showOrderingView: Bool = false
    @State private var selectedShop: CoffeeShop?
    
    @State private var shouldShowSearch: Bool = false
    @State private var searchText: String = ""

    private let radiusInKm: Double = 5.0
    
    private var nearbyLocations: [CoffeeShop] {
        guard let userLocation = locationManager.userLocation else { return [] }
        return shops.filter { location in
            let distance = calculateDistance(from: userLocation, to: location.location)
            return distance <= radiusInKm
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
    
    var body: some View {
        VStack {
            /* if searchText.isEmpty { */
                Map(position: $position) {
                    UserAnnotation()
                    ForEach(shops) { shop in
                        Annotation(shop.name, coordinate: shop.location) {
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
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        withAnimation {
                            shouldShowSearch = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .imageScale(.large)
                            .fontWeight(.semibold)
                    }
                    .padding(12)
                    .background(.thickMaterial)
                    .clipShape(Circle())
                    .padding([.trailing, .bottom])
                }
                .sheet(isPresented: $shouldShowSearch) {
                    VStack {
                        
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
                }
                .onChange(of: shops) { _, _ in
                    withAnimation {
                        position = .region(optimalRegion)
                    }
                }
                .navigationDestination(isPresented: $showOrderingView) {
                    if let selectedShop {
                        OrderView(selectedShop)
                    }
                }
            /*} else {
                List {
                    HStack {
                        
                    }
                }
            }*/
        }
        // .searchable(text: $searchText)
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
