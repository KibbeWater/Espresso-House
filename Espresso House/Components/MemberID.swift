//
//  MemberID.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//

import SwiftUI

struct MemberID: View {
    @State private var showInfo = false
    
    let id: String
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM h:mm:ss"
        return formatter.string(from: currentTime)
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Text("Member ID")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showInfo.toggle()
                } label: {
                    HStack {
                        Text("info")
                        Image(systemName: "info.circle")
                    }
                }
                .sheet(isPresented: $showInfo) {
                    MemberIDInfoSheet(isPresented: $showInfo)
                        .presentationDetents([.fraction(0.15), .medium])
                }
            }
            .padding(.horizontal)
            Barcode("\(id):member")
                .padding(.top, -8)
                .padding(.horizontal, 10)
            HStack {
                VStack(alignment: .leading) {
                    Text("Membership no:")
                    Text("\(id)")
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(formattedTime)
                        .monospacedDigit()
                        .onReceive(timer) { input in
                            currentTime = input
                        }
                    
                    Text("Pin: 0000")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

#Preview {
    NavigationStack {
        VStack {
            MemberID(id: SharedVars.shared.memberId ?? "")
            Spacer()
            MemberID(id: SharedVars.shared.memberId ?? "")
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.secondary.opacity(0.3), lineWidth: 2)
                    )
                .padding(.horizontal)
        }
    }
}
