//
//  MainView.swift
//  Espresso House
//
//  Created by KibbeWater on 8/12/24.
//

import SwiftUI
import SwiftData
import Kingfisher

struct MainView: View {
    @StateObject var viewModel: MainViewModel = MainViewModel()
    @Environment(\.activeOrderVM) private var activeOrderVM

    @State var isIdShown: Bool = false
    @State var isProfileShown: Bool = false
    @State var showActiveOrder: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Active order banner
                if activeOrderVM.hasActiveOrder {
                    Button {
                        showActiveOrder = true
                    } label: {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your order is in progress")
                                    .fontWeight(.semibold)
                                    .font(.subheadline)
                                if let order = activeOrderVM.latestOrder {
                                    Text(order.displayStatus)
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                    }
                }

                NavigationLink {
                    FikaHouseView()
                } label: {
                    FikaClubCard(fikaPoints: $viewModel.points)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .foregroundStyle(.primary)

                VStack {
                    HStack {
                        Text("Fika Fun")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .imageScale(.large)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal) {
                        HStack(spacing: 24) {
                            ForEach(viewModel.challenges) { challenge in
                                ProgressCard(title: challenge.heading, url: challenge.imageUrl, value: challenge.stepsDone, maxValue: challenge.totalSteps)
                                    .padding()
                                    .frame(width: UIScreen.main.bounds.size.width - 32)
                                    .background(Color(uiColor: .systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color.background.opacity(0.3))

                VStack {
                    HStack {
                        Text("Fika Offers")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(viewModel.coupons) { coupon in
                                CouponCard(coupon: coupon)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(.secondary.opacity(0.3), lineWidth: 2)
                                        )
                                    .frame(width: 300, height: 320)
                                    .padding(.horizontal)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
        }
        .refreshable {
            try? await viewModel.refresh()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Text("Hi \(viewModel.firstName)!")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 20) {
                    Button {
                        withAnimation {
                            isIdShown.toggle()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 20))
                            Text("My ID")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                    }
                    .sheet(isPresented: $isIdShown) {
                        NavigationStack {
                            IDSheet(
                                balance: viewModel.balance,
                                pinCode: viewModel.pinCode,
                                firstName: viewModel.firstName,
                                lastName: viewModel.lastName
                            )
                        }
                    }

                    Button {
                        withAnimation {
                            isProfileShown.toggle()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 20))
                            Text("Profile")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                    }
                    .sheet(isPresented: $isProfileShown) {
                        NavigationStack {
                            ProfileSheet(
                                firstName: viewModel.firstName,
                                lastName: viewModel.lastName
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.accent.opacity(0.95))
            .background(.ultraThinMaterial)
        }
        .navigationDestination(isPresented: $showActiveOrder) {
            ActiveOrderView()
        }
        .onChange(of: activeOrderVM.hasActiveOrder) { _, hasOrder in
            // Auto-open ActiveOrderView when a new order appears (e.g. after simulated checkout)
            if hasOrder && !showActiveOrder {
                showActiveOrder = true
            }
        }
    }
}

#Preview {
    MainView()
}
