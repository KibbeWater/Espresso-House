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
        location.isCurrentlyOpen
    }

    private var statusText: String {
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
                                Text(location.formattedHours)
                            }
                            .font(.caption)
                        }

                        if canOrder {
                            Image(systemName: "chevron.right")
                                .imageScale(.medium)
                        }
                    }
                    .foregroundStyle(.primary)
                    .contentShape(Rectangle())
                    .padding(12)
                }
                .buttonStyle(.plain)
                .disabled(!canOrder)
                .presentationCompactAdaptation(.popover)
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

    // Cached closest 100 shops — recalculated when shops load or user moves >100m
    @State private var sortedShops: [CoffeeShop] = []
    @State private var lastSortLocation: CLLocationCoordinate2D?
    private let resortThresholdMeters: Double = 100

    private var nearbyLocations: [CoffeeShop] {
        guard let userLocation = locationManager.userLocation else { return [] }
        return sortedShops.filter { location in
            let distance = calculateDistance(from: userLocation, to: location.location)
            return distance <= radiusInKm
        }
    }

    /// Sort shops by distance and keep closest 100. Called unconditionally
    /// when shop data changes, or when user moves >100m.
    private func sortShopsByDistance() {
        guard let userLocation = locationManager.userLocation else {
            sortedShops = Array(shops.prefix(100))
            return
        }

        lastSortLocation = userLocation
        let sorted = shops.sorted {
            calculateDistance(from: userLocation, to: $0.location) <
            calculateDistance(from: userLocation, to: $1.location)
        }
        sortedShops = Array(sorted.prefix(100))
    }

    /// Only re-sort if user has moved >100m since last sort
    private func resortIfMoved() {
        guard !shops.isEmpty,
              let userLocation = locationManager.userLocation else { return }

        if let last = lastSortLocation {
            let moved = CLLocation(latitude: last.latitude, longitude: last.longitude)
                .distance(from: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude))
            if moved < resortThresholdMeters { return }
        }

        sortShopsByDistance()
    }

    /// Shops filtered by search text (already sorted by distance)
    private var filteredShops: [CoffeeShop] {
        if searchText.isEmpty { return sortedShops }
        let query = searchText.lowercased()
        return sortedShops.filter {
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

            ShopListPanel(
                shops: filteredShops,
                searchText: $searchText,
                distanceText: distanceText,
                onSelectShop: { shop in
                    selectedShop = shop
                    showOrderingView = true
                }
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationDestination(isPresented: $showOrderingView) {
            if let selectedShop {
                OrderView(selectedShop)
            }
        }
        .onChange(of: shops) { _, _ in
            sortShopsByDistance()
            withAnimation {
                position = .region(optimalRegion)
            }
        }
        .onChange(of: locationManager.userLocation) { _, _ in
            resortIfMoved()
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

// MARK: - Shop List Panel (UIKit-backed drag for 60fps)

struct ShopListPanel: View {
    let shops: [CoffeeShop]
    @Binding var searchText: String
    let distanceText: (CoffeeShop) -> String?
    let onSelectShop: (CoffeeShop) -> Void

    var body: some View {
        PanelContainer {
            VStack(spacing: 0) {
                // Handle + header
                Capsule()
                    .fill(Color(.systemGray3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                HStack {
                    Text("Shops")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(shops.count) locations")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    TextField("Search by name or city", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .overlay(Color.accentColor.opacity(0.15))

                // Shop list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(shops) { shop in
                            let canOrder = shop.isCurrentlyOpen
                            Button {
                                if canOrder { onSelectShop(shop) }
                            } label: {
                                VStack(spacing: 0) {
                                    HStack(spacing: 14) {
                                        Circle()
                                            .fill(canOrder ? Color.accentColor.opacity(0.15) : Color.background.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                            .overlay {
                                                Image(systemName: "cup.and.saucer.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(canOrder ? Color.accentColor : .secondary)
                                            }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(shop.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(canOrder ? .primary : .secondary)
                                                .lineLimit(1)

                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(canOrder ? .green : .red)
                                                    .frame(width: 6, height: 6)
                                                if shop.isClosedToday {
                                                    Text("Closed today")
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

                                        Spacer(minLength: 0)

                                        VStack(alignment: .trailing, spacing: 2) {
                                            if let dist = distanceText(shop) {
                                                Text(dist)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if canOrder {
                                                Image(systemName: "chevron.right")
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(Color.accentColor.opacity(0.5))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())

                                    Divider()
                                        .overlay(Color.accentColor.opacity(0.08))
                                        .padding(.leading, 74)
                                }
                            }
                            .disabled(!canOrder)
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UIKit Panel Container

/// Wraps SwiftUI content in a UIKit view that uses UIPanGestureRecognizer
/// for buttery-smooth dragging. All drag state lives in UIKit — SwiftUI
/// never re-renders during a pan.
struct PanelContainer<Content: View>: UIViewControllerRepresentable {
    @ViewBuilder let content: Content

    func makeUIViewController(context: Context) -> PanelViewController<Content> {
        PanelViewController(rootContent: content)
    }

    func updateUIViewController(_ vc: PanelViewController<Content>, context: Context) {
        vc.updateContent(content)
    }
}

/// UIView subclass that passes touches outside its subviews to the views behind it.
class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}

class PanelViewController<Content: View>: UIViewController, UIGestureRecognizerDelegate {
    private var hostingController: UIHostingController<Content>
    private let panelView = UIView()

    // Snap stops (height of panel from bottom)
    private let peekHeight: CGFloat = 420
    private var halfHeight: CGFloat { view.bounds.height * 0.6 }
    private var fullHeight: CGFloat { view.bounds.height * 0.88 }

    private var currentSnapHeight: CGFloat = 420
    private var panStartY: CGFloat = 0

    init(rootContent: Content) {
        self.hostingController = UIHostingController(rootView: rootContent)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        // Use passthrough view so touches on the map area go through
        self.view = PassthroughView()
    }

    func updateContent(_ content: Content) {
        hostingController.rootView = content
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // Panel view — blend systemBackground with a subtle brand green tint
        let base = UIColor.systemBackground
        let brand = UIColor(named: "backgroundColor") ?? UIColor.systemBackground
        panelView.backgroundColor = UIColor { traits in
            let bg = base.resolvedColor(with: traits)
            let tint = brand.resolvedColor(with: traits)
            // Mix 92% system background + 8% brand color
            return UIColor(
                red: bg.red * 0.92 + tint.red * 0.08,
                green: bg.green * 0.92 + tint.green * 0.08,
                blue: bg.blue * 0.92 + tint.blue * 0.08,
                alpha: 1
            )
        }
        panelView.layer.cornerRadius = 20
        panelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panelView.clipsToBounds = true
        panelView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panelView)

        // Hosting controller
        addChild(hostingController)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // Extend panel to the very bottom of the screen (past safe area)
        NSLayoutConstraint.activate([
            panelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100),

            hostingController.view.topAnchor.constraint(equalTo: panelView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: panelView.bottomAnchor),
        ])

        // Height constraint (animated)
        let heightConstraint = panelView.heightAnchor.constraint(equalToConstant: peekHeight)
        heightConstraint.isActive = true
        self.panelHeightConstraint = heightConstraint

        // Pan gesture only on the handle area at the top of the panel
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        panelView.addGestureRecognizer(pan)
    }

    private var panelHeightConstraint: NSLayoutConstraint?

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)

        switch recognizer.state {
        case .began:
            panStartY = panelHeightConstraint?.constant ?? currentSnapHeight

        case .changed:
            let newHeight = panStartY - translation.y
            let clamped = max(200, min(newHeight, fullHeight))
            panelHeightConstraint?.constant = clamped

        case .ended, .cancelled:
            let velocity = recognizer.velocity(in: view).y
            let currentH = panelHeightConstraint?.constant ?? currentSnapHeight

            // Project where it would end up based on velocity
            let projected = currentH - velocity * 0.15
            let snaps = [peekHeight, halfHeight, fullHeight]
            let nearest = snaps.min(by: { abs($0 - projected) < abs($1 - projected) })!
            currentSnapHeight = nearest

            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction]
            ) {
                self.panelHeightConstraint?.constant = nearest
                self.view.layoutIfNeeded()
            }

        default: break
        }
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let sv = view as? UIScrollView { return sv }
        for sub in view.subviews {
            if let found = findScrollView(in: sub) { return found }
        }
        return nil
    }

    // MARK: UIGestureRecognizerDelegate

    /// Only begin the pan if it's a clear vertical drag, not a tap
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: panelView)
        // Require dominant vertical movement to avoid stealing taps
        return abs(velocity.y) > abs(velocity.x)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let scrollView = findScrollView(in: panelView) else { return false }

        let velocity = pan.velocity(in: panelView)
        let isScrollAtTop = scrollView.contentOffset.y <= 0

        if isScrollAtTop && velocity.y > 0 {
            scrollView.isScrollEnabled = false
            DispatchQueue.main.async { scrollView.isScrollEnabled = true }
            return false
        }

        if panelHeightConstraint?.constant ?? 0 < fullHeight - 10 {
            scrollView.isScrollEnabled = false
            DispatchQueue.main.async { scrollView.isScrollEnabled = true }
            return false
        }

        return true
    }
}


private extension UIColor {
    var red: CGFloat {
        var r: CGFloat = 0; getRed(&r, green: nil, blue: nil, alpha: nil); return r
    }
    var green: CGFloat {
        var g: CGFloat = 0; getRed(nil, green: &g, blue: nil, alpha: nil); return g
    }
    var blue: CGFloat {
        var b: CGFloat = 0; getRed(nil, green: nil, blue: &b, alpha: nil); return b
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
