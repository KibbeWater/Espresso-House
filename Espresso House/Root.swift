//
//  Espresso_HouseApp.swift
//  Espresso House
//
//  Created by KibbeWater on 8/12/24.
//

import SwiftUI
import SwiftData
import Kingfisher

@main
struct Root: App {
    @State private var isUpsideDown = false
    @State private var previousBrightness: CGFloat?
    @StateObject private var sharedVars = SharedVars.shared
    @Environment(\.espressoAPI) var api: EspressoAPI
    @State private var activeOrderVM = ActiveOrderViewModel()

    #if DEBUG
    @State private var showDebugMenu = false
    #endif

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    func checkStorage() {
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                print("Disk cache size: \(Double(size) / 1024 / 1024) MB")
            case .failure(let error):
                print(error)
            }
        }
    }

    func prefetchMenu() {
        Task {
            guard let menu = try? await api.menu.getMenu() else { return }

            let productImageProcessor = DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))

            let urls = menu.flatMap({ $0.products.compactMap({ $0.image }) }).map({ URL(string: $0) }).filter({ $0 != nil }) as! [URL]
            print("Prefecting \(urls.count) images")
            let prefetcher = ImagePrefetcher(
                urls: urls,
                options: [
                    .processor(productImageProcessor),
                    .scaleFactor(UIScreen.main.scale),
                    .retryStrategy(DelayRetryStrategy(
                        maxRetryCount: 5,
                        retryInterval: .seconds(3)
                    ))
                ]
            )
            prefetcher.start()
        }
    }

    var body: some Scene {
        WindowGroup {
            if sharedVars.isAuthenticated {
                TabView(selection: $sharedVars.selectedTab) {
                    Tab("Start", systemImage: "house", value: 0) {
                        NavigationStack {
                            MainView()
                        }
                    }

                    Tab("Wallet", systemImage: "wallet.bifold", value: 1) {
                        NavigationStack {
                            WalletView()
                        }
                    }

                    Tab("Order", systemImage: "takeoutbag.and.cup.and.straw", value: 2) {
                        NavigationStack {
                            ShopsView()
                        }
                    }
                }
                .modifier(BottomAccessoryModifier(activeOrderVM: activeOrderVM))
                .environment(\.espressoAPI, api)
                .environment(\.activeOrderVM, activeOrderVM)
                .sensitiveUpsideDownDetection(isUpsideDown: $isUpsideDown)
                .overlay {
                    ZStack {
                        if isUpsideDown {
                            Color.primary.opacity(0.5)
                                .ignoresSafeArea()
                            VStack {
                                Spacer()
                                MemberID(id: sharedVars.memberId ?? "")
                                    .background(Color(uiColor: .systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(.secondary.opacity(0.3), lineWidth: 2)
                                        )
                                    .padding(.horizontal)
                            }
                            .rotationEffect(.degrees(-180))
                        }
                    }
                }
                .onChange(of: isUpsideDown) { _, upsideDown in
                    if upsideDown {
                        previousBrightness = UIScreen.main.brightness
                        UIScreen.main.brightness = 1.0
                    } else if let saved = previousBrightness {
                        UIScreen.main.brightness = saved
                        previousBrightness = nil
                    }
                }
                .onAppear {
                    checkStorage()
                    print("Prefetch images")
                    prefetchMenu()
                    // Check for active orders on launch
                    Task {
                        await activeOrderVM.fetchOrders(api: api.order)
                        if activeOrderVM.hasActiveOrder {
                            activeOrderVM.startPolling(api: api.order)
                        }
                    }
                }
                #if DEBUG
                .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                    showDebugMenu = true
                }
                .sheet(isPresented: $showDebugMenu) {
                    DebugMenuView(activeOrderVM: activeOrderVM)
                }
                #endif
            } else {
                LoginView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Bottom Accessory Modifier

struct BottomAccessoryModifier: ViewModifier {
    @Bindable var activeOrderVM: ActiveOrderViewModel

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content
                .tabViewBottomAccessory(isEnabled: activeOrderVM.hasActiveOrder) {
                    ActiveOrderAccessory(activeOrderVM: activeOrderVM)
                }
        } else {
            content
        }
    }
}

// MARK: - Active Order Bottom Accessory

struct ActiveOrderAccessory: View {
    @Bindable var activeOrderVM: ActiveOrderViewModel

    var body: some View {
        if let order = activeOrderVM.latestOrder {
            HStack(spacing: 8) {
                Image(systemName: statusIcon(for: order))
                    .foregroundStyle(statusColor(for: order))
                Text(statusText(for: order))
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
                if let pin = order.orderPinCode {
                    Text("PIN: \(pin)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func statusIcon(for order: ActiveOrder) -> String {
        switch order.status {
        case "Delivered": return "checkmark.circle.fill"
        case "ReadyForPickup": return "cup.and.saucer.fill"
        case "UnderProduction": return "flame.fill"
        default: return "clock.fill"
        }
    }

    private func statusColor(for order: ActiveOrder) -> Color {
        switch order.status {
        case "Delivered", "ReadyForPickup": return .green
        case "UnderProduction": return .orange
        default: return .accentColor
        }
    }

    private func statusText(for order: ActiveOrder) -> String {
        switch order.status {
        case "Delivered": return "Order complete"
        case "ReadyForPickup": return "Order ready!"
        case "UnderProduction": return "Preparing your order..."
        default: return "Order placed"
        }
    }
}

#Preview {
    MainView()
}
