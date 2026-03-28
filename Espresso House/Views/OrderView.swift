//
//  OrderView.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import SwiftUI

struct OrderView: View {
    @Environment(\.espressoAPI) private var api
    @State private var menu: [ShopMenuCategory] = []
    @State private var sections: [String] = []
    @State private var activeTags: Dictionary<String, String> = [:]

    @State var cart: CartViewModel
    @Environment(\.activeOrderVM) private var activeOrderVM

    @State private var selectedCategory: String = ""
    @State private var isLoading: Bool = true

    @State private var selectedProduct: ShopMasterProduct? = nil
    @State private var showProductDetails: Bool = false
    @State private var showCheckout: Bool = false
    @State private var showActiveOrder: Bool = false

    private let allTag = "All"

    let shop: CoffeeShop

    private var orderService: any OrderServiceProtocol {
        #if DEBUG
        if DebugSettings.shared.isSimulating {
            return MockOrderService()
        }
        #endif
        return api.order
    }

    init(_ shop: CoffeeShop) {
        self.shop = shop
        self._cart = State(initialValue: CartViewModel(shop: shop))
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            self.menu = try await orderService.getShopMenu(shopNumber: String(shop.id))
        } catch {
            // Fallback: try the generic menu and map to ShopMenuCategory
            print("[OrderView] Shop menu failed: \(error), falling back to generic menu")
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
        }
    }

    func getCategoryTags(_ category: ShopMenuCategory) -> [String] {
        let tags = category.masterProducts.flatMap { $0.menuTags }
        var count: Dictionary<String, Int> = tags.reduce(into: [:]) { $0[$1.text, default: 0] += 1 }
        count["All"] = Int.max

        return count.keys
            .sorted { count[$0]! > count[$1]! }
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

                // Loading state
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading menu...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Category tabs
                HStack {
                    Image(systemName: "magnifyingglass")
                        .padding(.bottom, 8)
                    Spacer()
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(sections, id: \.self) { section in
                                Button(section) {
                                    selectedCategory = section
                                }
                                .padding(.leading)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal)

                // Products
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(menu) { category in
                            VStack {
                                HStack {
                                    Text(category.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    let tags = getCategoryTags(category)

                                    HStack {
                                        ForEach(tags, id: \.self) { tag in
                                            if isTagActive(category.name, tag: tag) {
                                                Button(tag) {
                                                    withAnimation {
                                                        activeTags[category.name] = nil
                                                    }
                                                }
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.accentColor)
                                                .padding(.horizontal)
                                                .padding(.vertical, 8)
                                                .background(Color.background.opacity(0.4))
                                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                            } else {
                                                Button(tag) {
                                                    withAnimation {
                                                        activeTags[category.name] = tag
                                                    }
                                                }
                                                .foregroundStyle(.primary)
                                                .fontWeight(.medium)
                                                .padding(.horizontal)
                                                .padding(.vertical, 8)
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
                                                ProductCard(
                                                    product: masterProduct
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            .id(category.name)
                            .padding(.horizontal)
                            .padding(.vertical)
                        }

                        // Spacer for cart bar
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

            // Cart bar
            if !cart.isEmpty {
                Button {
                    showCheckout = true
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
                    .background(.ultraThinMaterial)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
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
