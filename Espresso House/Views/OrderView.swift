//
//  OrderView.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import SwiftUI
import Kingfisher

struct OrderView: View {
    @Environment(\.espressoAPI) private var api
    @State private var menu: [ShopMenuCategory] = []
    @State private var sections: [String] = []
    @State private var activeTags: Dictionary<String, String> = [:]

    @State var cart: CartViewModel
    @Environment(\.activeOrderVM) private var activeOrderVM

    @State private var selectedCategory: String = ""
    @State private var isLoading: Bool = true
    @State private var shopUnavailable: Bool = false
    @State private var previousOrders: [SavedOrder] = []

    @State private var selectedProduct: ShopMasterProduct? = nil
    @State private var showProductDetails: Bool = false
    @State private var showCart: Bool = false
    @State private var showCheckout: Bool = false
    @State private var showActiveOrder: Bool = false

    private let allTag = "All"

    let shop: CoffeeShop

    private var orderService: any OrderServiceProtocol {
        #if DEBUG
        if DebugSettings.shared.isSimulating {
            return MockOrderService.shared
        }
        #endif
        return api.order
    }

    init(_ shop: CoffeeShop) {
        self.shop = shop
        self._cart = State(initialValue: CartViewModel(shop: shop))
    }

    @State private var shopOfflineMessage: String?

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Check model flags first
        if !shop.preorderOnline {
            shopUnavailable = true
            return
        }

        // Check runtime shop status
        if let status = try? await orderService.getShopStatus(shopNumber: String(shop.id)) {
            if !status.isOnline {
                shopUnavailable = true
                shopOfflineMessage = "This shop is not accepting orders right now."
                return
            }
        }

        do {
            self.menu = try await orderService.getShopMenu(shopNumber: String(shop.id))
        } catch {
            print("[OrderView] Shop menu failed: \(error)")
            // If the shop is closed, don't fall back — show unavailable
            if !shop.isCurrentlyOpen {
                shopUnavailable = true
                return
            }
            print("[OrderView] Falling back to generic menu")
            if let genericMenu = try? await api.menu.getMenu() {
                self.menu = genericMenu.map { category in
                    ShopMenuCategory(
                        name: category.name,
                        masterProducts: category.products.map { product in
                            ShopMasterProduct(
                                name: product.name,
                                image: product.image,
                                menuTags: product.menuTags.map { ShopMasterProduct.MenuProductTag(priority: $0.priority, text: $0.text) },
                                configurations: [
                                    ShopProduct(
                                        articleNumber: product.id,
                                        articleName: product.name,
                                        img: product.image,
                                        description: nil,
                                        shortDescription: nil,
                                        navName: "Standard",
                                        outOfStock: false,
                                        icon: nil,
                                        iconSelected: nil,
                                        articleUrl: nil,
                                        isComplexConfiguration: false,
                                        price: nil,
                                        currency: "SEK",
                                        levels: [],
                                        upsell: nil,
                                        extraChoices: nil
                                    )
                                ]
                            )
                        }
                    )
                }
            }
        }

        if !menu.isEmpty {
            self.sections = menu.map { $0.name }
            if selectedCategory.isEmpty {
                selectedCategory = sections.first ?? ""
            }
        }

        // Load local order history, validated against current menu
        let menuArticles = Set(menu.flatMap { $0.masterProducts.flatMap { $0.articles.map { $0.articleNumber } } })
        self.previousOrders = OrderHistory.shared.ordersForShop(shop.id).filter { order in
            // Only show if all items still exist on the menu
            order.items.allSatisfy { menuArticles.contains($0.articleNumber) }
        }
    }

    func getCategoryTags(_ category: ShopMenuCategory) -> [String] {
        let tags = category.masterProducts.flatMap { $0.menuTags }
        var count: Dictionary<String, Int> = tags.reduce(into: [:]) { $0[$1.text, default: 0] += 1 }
        count["All"] = Int.max

        // Remove tags that match the category name since they're redundant with "All"
        count.removeValue(forKey: category.name)

        return count.keys
            .sorted { lhs, rhs in
                let lhsCount = count[lhs]!
                let rhsCount = count[rhs]!
                if lhsCount != rhsCount { return lhsCount > rhsCount }
                return lhs < rhs
            }
    }

    func isTagActive(_ categoryName: String, tag: String) -> Bool {
        activeTags[categoryName]?.lowercased() ?? allTag.lowercased() == tag.lowercased()
    }

    func filterTag(_ products: [ShopMasterProduct], tag: String) -> [ShopMasterProduct] {
        products.filter { tag == allTag || $0.menuTags.contains(where: { $0.text == tag }) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Active order banner
                if activeOrderVM.hasActiveOrder {
                    Button {
                        showActiveOrder = true
                    } label: {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                            Text("Active order — tap to view")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                    }
                }

                #if DEBUG
                if DebugSettings.shared.isSimulating {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("SIMULATED ORDER")
                            .fontWeight(.bold)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                }
                #endif

                if shopUnavailable {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: shop.preorderOnline ? "clock.badge.xmark" : "bag.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(shop.preorderOnline ? "Shop not available" : "Online ordering not available")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(shopOfflineMessage
                             ?? (!shop.preorderOnline
                                 ? "This shop doesn't support online ordering yet."
                                 : shop.isClosedToday
                                    ? "This shop is closed today."
                                    : "This shop is currently closed.\nOpen \(shop.formattedHours)"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading menu...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Category tabs + menu
                    menuBrowserView
                }
            }

            // Cart bar
            if !cart.isEmpty {
                Button {
                    showCart = true
                } label: {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("\(cart.totalItems) \(cart.totalItems == 1 ? "item" : "items")")
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(cart.totalPrice)) \(cart.currency)")
                            .fontWeight(.bold)
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .modifier(GlassCartBarModifier())
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: cart.isEmpty)
        .navigationTitle(shop.name)
        .sheet(isPresented: $showProductDetails) {
            if let product = selectedProduct {
                ProductSheet(masterProduct: product, cart: cart)
            }
        }
        .sheet(isPresented: $showCart) {
            CartSheet(cart: cart) {
                showCheckout = true
            }
        }
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView(cart: cart)
        }
        .navigationDestination(isPresented: $showActiveOrder) {
            ActiveOrderView()
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
    }

    // MARK: - Menu Browser

    private var menuBrowserView: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(sections, id: \.self) { section in
                        Button {
                            selectedCategory = section
                        } label: {
                            Text(section)
                                .font(.subheadline)
                                .fontWeight(selectedCategory == section ? .semibold : .regular)
                                .foregroundStyle(selectedCategory == section ? Color.accentColor : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategory == section
                                        ? Color.accentColor.opacity(0.12)
                                        : Color(.systemGray6)
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }

            // Products
            ScrollViewReader { proxy in
                ScrollView {
                    // Order Again
                    if !previousOrders.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Order Again")
                                .font(.title2)
                                .fontWeight(.semibold)

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(previousOrders) { order in
                                        Button {
                                            for item in order.items {
                                                cart.addItem(product: item.toShopProduct(), quantity: item.quantity)
                                            }
                                        } label: {
                                            PreviousOrderCard(order: order)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    ForEach(menu) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            let tags = getCategoryTags(category)
                            if tags.count > 1 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(tags, id: \.self) { tag in
                                            let active = isTagActive(category.name, tag: tag)
                                            Button {
                                                withAnimation(.snappy(duration: 0.25)) {
                                                    activeTags[category.name] = active ? nil : tag
                                                }
                                            } label: {
                                                Text(tag)
                                                    .font(.subheadline)
                                                    .fontWeight(active ? .semibold : .regular)
                                                    .foregroundStyle(active ? Color.accentColor : .primary)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(active ? Color.accentColor.opacity(0.12) : Color(.systemGray6))
                                                    .clipShape(Capsule())
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(active ? Color.accentColor.opacity(0.3) : .clear, lineWidth: 1)
                                                    )
                                                    .animation(.snappy(duration: 0.25), value: active)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(filterTag(category.masterProducts, tag: activeTags[category.name] ?? allTag)) { masterProduct in
                                        Button {
                                            selectedProduct = masterProduct
                                            showProductDetails = true
                                        } label: {
                                            ProductCard(product: masterProduct)
                                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .id(category.name)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    if !cart.isEmpty {
                        Spacer().frame(height: 80)
                    }
                }
                .onChange(of: selectedCategory) { _, _ in
                    guard !selectedCategory.isEmpty else { return }
                    withAnimation {
                        proxy.scrollTo(selectedCategory, anchor: .top)
                    }
                }
            }
        }
    }
}

struct PreviousOrderCard: View {
    let order: SavedOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image area — matches ProductCard dimensions
            VStack {
                Spacer()
                if let imgUrl = order.firstImageURL, let url = URL(string: imgUrl) {
                    KFImage(url)
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .frame(width: 172, height: 132)
            .background(Color(.systemGray6))

            VStack(alignment: .leading, spacing: 2) {
                Text(order.displayName)
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if order.totalPrice > 0 {
                    Text("\(Int(order.totalPrice)) \(order.currency)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 172)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}

struct GlassCartBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
        }
    }
}

#Preview {
    NavigationStack {
        OrderView(CoffeeShop(
            id: 322,
            name: "Smedjan Luleå",
            address1: "Storgatan 36",
            address2: "",
            postalCode: "972 31",
            city: "Luleå",
            country: "Sweden",
            phoneNumber: "0700000000",
            latitude: 65.584246,
            longitude: 22.152694,
            wifi: true,
            childFriendly: true,
            handicapFriendly: true,
            expressCheckout: true,
            takeAwayOnly: false,
            preorderOnline: true,
            todayOpenFrom: "08:00:00",
            todayOpenTo: "20:00:00"
        ))
    }
}
