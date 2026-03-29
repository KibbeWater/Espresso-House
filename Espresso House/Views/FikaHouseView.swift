//
//  FikaHouseView.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI
import Kingfisher

struct FikaHouseView: View {
    @State private var isExtended = true
    @State private var offset = CGFloat.zero
    
    @State private var sheetOpen: Bool = false
    
    @StateObject private var viewModel = FikaHouseViewModel()
    
    let extensionThreshold: Float = 10
    
    @Namespace private var animationNamespace
    
    var infoCounter: some View {
        VStack {
            Text("\(viewModel.points)")
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 82))
                .fontWeight(.bold)
        }
        .matchedGeometryEffect(id: "counter", in: animationNamespace)
    }
    
    var infoPtsBtn: some View {
        Button {
            sheetOpen.toggle()
        } label: {
            HStack(spacing: 4) {
                Text("More info")
                Image(systemName: "info.circle")
            }
        }
        .foregroundStyle(Color.accentColor)
        .matchedGeometryEffect(id: "moreInfo", in: animationNamespace)
        .sheet(isPresented: $sheetOpen) {
            PointInfoSheet()
        }
    }
    
    var infoPoints: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fika Points")
                .font(.title2)
                .fontWeight(.semibold)
                .matchedGeometryEffect(id: "pointsText", in: animationNamespace)
            
            infoPtsBtn
        }
    }
    
    var infoPointsExt: some View {
        VStack(spacing: 4) {
            Text("Fika Points")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .matchedGeometryEffect(id: "pointsText", in: animationNamespace)
            
            infoPtsBtn
        }
    }
    
    func toggleExtended() {
        withAnimation {
            isExtended.toggle()
        }
    }
    
    var body: some View {
        ZStack {
            Color.background
                .opacity(0.6)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                if isExtended {
                    VStack(spacing: 20) {
                        infoCounter
                        infoPointsExt
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack(spacing: 28) {
                        infoCounter
                        infoPoints
                        Spacer()
                    }
                    .padding(.leading)
                    .padding(.bottom, 8)
                }
                
                Spacer()
                
                VStack {
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .background(Color(uiColor: .systemBackground))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    topTrailingRadius: 24
                ))
                
                VStack {
                    HStack {
                        Text("Fika for you")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible())
                        ]) {
                            ForEach(viewModel.offers) { offer in
                                VStack {
                                    KFImage(offer.imageUrl)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .background(.background.opacity(0.3))
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(offer.heading)
                                                .font(.headline)
                                                .fontWeight(.medium)
                                            Text("\(offer.points) Fika Points")
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.bottom, 10)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.bottom, 12)
                            }
                        }
                        .padding(.horizontal)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self,
                                                   value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { off in
                            let shouldExtend = (Float(off) - extensionThreshold) < 0
                            if shouldExtend != isExtended {
                                withAnimation {
                                    isExtended = shouldExtend
                                }
                            }
                        }
                    }
                    .coordinateSpace(name: "scroll")
                }
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemBackground))
            }
        }
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    FikaHouseView()
}
