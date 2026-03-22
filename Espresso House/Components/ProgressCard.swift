//
//  ProgressCard.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//

import SwiftUI
import Kingfisher

struct ProgressCard: View {
    let title: String
    
    let url: URL?
    let systemName: String?
    let value: Int
    
    let minValue: Int = 0
    let maxValue: Int
    
    init(title: String, systemName: String, value: Int, maxValue: Int = 10) {
        self.title = title
        self.systemName = systemName
        self.url = nil
        self.value = value
        self.maxValue = maxValue
    }
    
    init(title: String, url: URL, value: Int, maxValue: Int = 10) {
        self.title = title
        self.url = url
        self.systemName = nil
        self.value = value
        self.maxValue = maxValue
    }
    
    var body: some View {
        HStack(spacing: 24) {
            Gauge(value: Float(value), in: Float(minValue)...Float(maxValue)) {
                Text("\(value) / \(maxValue)")
            }
            .frame(width: 100, height: 100)
            .gaugeStyle(systemName != nil ? PieGaugeStyle(systemName!) : PieGaugeStyle(url!))
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct PieGaugeStyle: GaugeStyle {
    private let startAngle: Double = -220 // Start at bottom left of the gap
    private let endAngle: Double = 40     // End at bottom right of the gap
    
    private let systemName: String?
    private let url: URL?
    
    init(_ systemName: String) {
        self.systemName = systemName
        self.url = nil
    }
    
    init(_ url: URL) {
        self.url = url
        self.systemName = nil
    }
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Background track (unfilled portion)
                Path { path in
                    path.addArc(
                        center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                        radius: geometry.size.width / 2,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(endAngle),
                        clockwise: false
                    )
                }
                .stroke(Color.background.opacity(0.2), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                
                // Filled portion of the gauge
                Path { path in
                    path.addArc(
                        center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                        radius: geometry.size.width / 2,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(startAngle + (configuration.value * 300)), // 300 degrees total arc
                        clockwise: false
                    )
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                
                if let systemName {
                    Image(systemName: systemName)
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                } else if let url {
                    KFImage(url)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Current value text
                configuration.label
                    .font(.headline)
                    .fontWeight(.semibold)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 12)
            }
        }
    }
}

#Preview {
    ProgressCard(title: "Visit us every week in December!", systemName: "trash", value: 3)
        .padding(.horizontal)
        .padding(.vertical, 32)
        .background(.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding()
    
    ProgressCard(title: "Visit us every week in December!", url: URL(string: "https://myespressohouse.azureedge.net/images/721a5869-25df-47c4-bb63-fe79996d17aa.png")!, value: 3)
        .padding(.horizontal)
        .padding(.vertical, 32)
        .background(.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding()
}
