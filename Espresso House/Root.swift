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
                    NavigationStack {
                        MainView()
                    }
                    .tabItem {
                        Label("Start", systemImage: "house")
                    }
                    .tag(0)

                    NavigationStack {
                        WalletView()
                    }
                    .tabItem {
                        Label("Wallet", systemImage: "wallet.bifold")
                    }
                    .tag(1)

                    NavigationStack {
                        ShopsView()
                    }
                    .tabItem {
                        Label("Order", systemImage: "takeoutbag.and.cup.and.straw")
                    }
                    .tag(2)

                    NavigationStack {
                        ShopsView()
                    }
                    .tabItem {
                        Label("More", systemImage: "ellipsis")
                    }
                    .tag(3)
                }
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

#Preview {
    MainView()
}
