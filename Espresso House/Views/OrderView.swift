//
//  OrderView.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import SwiftUI

struct OrderView: View {
    @Environment(\.espressoAPI) private var api
    @State private var menu: [MenuCategory] = []
    @State private var sections: [String] = []
    @State private var activeTags: Dictionary<MenuCategory, String> = [:]
    
    @State private var cart: [MenuProduct] = []

    @State private var selectedCategory: String = ""
    
    @State private var selectedProduct: MenuProduct? = nil
    @State private var showProductDetails: Bool = false
    
    private let allTag = "All"
    
    private let shop: CoffeeShop
    
    init(_ shop: CoffeeShop) {
        self.shop = shop
    }
    
    func loadData() async throws {
        self.menu = (try? await api.menu.getMenu()) ?? []
        
        if !menu.isEmpty {
            self.sections = menu.map({ $0.name })
        }
    }
    
    func getCategorySections(_ category: MenuCategory) -> [String] {
        category.products.map({ $0.name })
    }
    
    func getCategoryTags(_ category: MenuCategory) -> [String] {
        let tags = category.products.flatMap({ $0.menuTags })
        var count: Dictionary<String, Int> = tags.reduce(into: [:]) { $0[$1.text, default: 0] += 1 }
        count["All"] = Int.max
        
        return count.keys
            .sorted { count[$0]! > count[$1]! }
    }
    
    func isTagActive(_ category: MenuCategory, tag: String) -> Bool {
        activeTags[category]?.lowercased() ?? allTag.lowercased() == tag.lowercased()
    }
    
    func filterTag(_ category: [MenuProduct], tag: String) -> [MenuProduct] {
        category.filter { tag == allTag || $0.menuTags.contains(where: { $0.text == tag }) }
    }
    
    var body: some View {
        VStack {
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
            
            
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(menu, id: \.name) { category in
                        VStack {
                            HStack {
                                Text(category.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                                NavigationLink {
                                    Text("Hello, World!")
                                } label: {
                                    Image(systemName: "arrow.right")
                                        .imageScale(.large)
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                let tags = getCategoryTags(category)
                                
                                HStack {
                                    ForEach(tags, id: \.self) { tag in
                                        if isTagActive(category, tag: tag) {
                                            Button(tag) {
                                                withAnimation {
                                                    activeTags[category] = nil
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
                                                    activeTags[category] = tag
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
                                    ForEach(filterTag(category.products, tag: activeTags[category] ?? allTag)) { item in
                                        Button {
                                            selectedProduct = item
                                            showProductDetails = true
                                        } label: {
                                            ProductCard(product: item)
                                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .sheet(isPresented: $showProductDetails) {
                                    
                                }
                            }
                        }
                        .id(category.name)
                        .padding(.horizontal)
                        .padding(.vertical)
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
        .navigationTitle(shop.name)
        .onAppear {
            Task {
                try await loadData()
            }
        }
    }
}

#Preview {
    OrderView(CoffeeShop(
        id: 101,
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
