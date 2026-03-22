//
//  Menu.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import Foundation

public struct MenuCategory: Codable, Equatable, Hashable {
    public var name: String
    public var products: [MenuProduct]
    
    enum CodingKeys: String, CodingKey {
        case name
        case products = "masterProducts"
    }
    
    public static func == (lhs: MenuCategory, rhs: MenuCategory) -> Bool {
        lhs.name == rhs.name
    }
}

public struct MenuProduct: Codable, Hashable, Identifiable {
    public var id: String { get { defaultArticleNumber } }
    public var name: String
    public var image: String?
    public var menuTags: [Tags]
    
    private var defaultArticleNumber: String
    
    public init(name: String, image: String? = nil, menuTags: [Tags], defaultArticleNumber: String) {
        self.name = name
        self.image = image
        self.menuTags = menuTags
        self.defaultArticleNumber = defaultArticleNumber
    }
    
    public struct Tags: Codable, Equatable, Hashable {
        public var priority: Int
        public var text: String
    }
}
