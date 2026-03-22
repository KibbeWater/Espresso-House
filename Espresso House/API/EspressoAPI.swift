//
//  HockeyAPI.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//


import Foundation

public class EspressoAPI: ObservableObject {
    public let menu: MenuServiceProtocol
    public let shop: ShopServiceProtocol
    public let member: MemberServiceProtocol
    public let fika: FikaServiceProtocol
    let auth: AuthServiceProtocol

    public static let shared = EspressoAPI()

    public init() {
        let networkManager = NetworkManager()

        self.menu = MenuService(networkManager: networkManager)
        self.shop = ShopService(networkManager: networkManager)
        self.member = MemberService(networkManager: networkManager)
        self.fika = FikaService(networkManager: networkManager)
        self.auth = AuthService(networkManager: networkManager)
    }
}
