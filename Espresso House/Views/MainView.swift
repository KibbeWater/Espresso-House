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
    
    @State var isIdShown: Bool = false
    @State var isProfileShown: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack {
                    Spacer()
                    Text("Hi User!")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button {
                        withAnimation {
                            isIdShown.toggle()
                        }
                    } label: {
                        VStack {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 20))
                            Spacer()
                            Text("My ID")
                                .font(.callout)
                                .fontWeight(.medium)
                                .padding(.top, -4)
                        }
                        .foregroundStyle(.white)
                    }
                    .sheet(isPresented: $isIdShown) {
                        NavigationStack {
                            IDSheet(isPresented: $isIdShown)
                        }
                    }
                    
                    Button {
                        withAnimation {
                            isProfileShown.toggle()
                        }
                    } label: {
                        VStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 20))
                            Spacer()
                            Text("Profile")
                                .font(.callout)
                                .fontWeight(.medium)
                                .padding(.top, -4)
                        }
                        .foregroundStyle(.white)
                    }
                    .sheet(isPresented: $isProfileShown) {
                        NavigationStack {
                            ProfileSheet(isPresented: $isProfileShown)
                        }
                    }
                }
                .frame(height: 10)
            }
            .frame(height: 30)
            .padding([.horizontal, .vertical])
            .background(.accent)
            
            ScrollView {
                VStack(spacing: 0) {
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
            
            Button("Clear Cache") {
                ImageCache.default.clearDiskCache {
                    print("Disk cache cleared.")
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    MainView()
}
