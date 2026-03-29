//
//  PointInfoSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI

struct PointInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    private func bold(_ text: String) -> Text {
        Text(text).fontWeight(.semibold)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("How to earn and redeem Fika Points")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 4)

                    Text("\(bold("Shop")) For every 50kr spent on the same receipt")

                    VStack(alignment: .leading, spacing: 18) {
                        Text("\(bold("Top up")) You will receive points every time you top up money using our in-app service!")

                        Text("100 kr = 3 Fika Points")
                        Text("300 kr = 10 Fika Points")
                        Text("500 kr = 20 Fika Points")
                    }

                    Text("\(bold("Complete Fika Fun Challenges")) You earn Fika Points when you complete challenges in the app. Check out our Fika Fun universe on the front page of the app now!")

                    Text("\(bold("Into a Focaccia, Fika or Frapino?")) Redeem your Fika Points and claim rewards anytime, anywhere, directly from the app in Fika House.")

                    Text("Collected Fika Points are valid for 12 months.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Fika Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text("")
        .sheet(isPresented: .constant(true)) {
            PointInfoSheet()
        }
}
