//
//  ProfileSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//


import SwiftUI

struct ProfileSheet: View {
    let defaultPicture: URL = URL(string: "https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg")!

    @Environment(\.dismiss) private var dismiss
    var firstName: String = ""
    var lastName: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                AsyncImage(url: defaultPicture) { img in
                    img.image?
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                }
                .frame(width: 64, height: 64)
                .overlay {
                    Circle()
                        .stroke(Color.background, lineWidth: 2)
                }
                .padding(.top)

                Text("\(firstName) \(lastName)")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(uiColor: .label))

                NavigationLink("Edit Profile") {
                    Text("Test")
                }
                .padding(.bottom)

                VStack(spacing: 0) {
                    profileRow(
                        icon: "creditcard",
                        iconBackground: Color.accentColor.opacity(0.2),
                        iconColor: Color.accentColor,
                        title: "Payment Cards",
                        titleColor: Color(uiColor: .label)
                    ) {
                        SharedVars.shared.pendingNavigation = .walletPaymentCards
                        SharedVars.shared.selectedTab = 1
                        dismiss()
                    }

                    profileRow(
                        icon: "trash",
                        iconBackground: Color.accentColor.opacity(0.2),
                        iconColor: Color.accentColor,
                        title: "Delete History",
                        titleColor: .red.opacity(0.8)
                    ) {
                        // TODO: Navigate to delete history
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                profileRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconBackground: Color.red.opacity(0.2),
                    iconColor: .red,
                    title: "Sign Out",
                    titleColor: .red,
                    showChevron: false
                ) {
                    SharedVars.shared.logout()
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func profileRow(
        icon: String,
        iconBackground: Color,
        iconColor: Color,
        title: String,
        titleColor: Color,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .padding(8)
                    .background(iconBackground)
                    .foregroundStyle(iconColor)
                    .clipShape(Circle())
                    .padding(.trailing, 10)

                Text(title)
                    .foregroundStyle(titleColor)
                    .fontWeight(.medium)

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProfileSheet()
    }
}
