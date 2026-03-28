//
//  ProfileSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//


import SwiftUI

struct ProfileSheet: View {
    let defaultPicture: URL = URL(string: "https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg")!
    
    @Binding var isPresented: Bool
    var firstName: String = ""
    var lastName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader("Profile", isPresented: $isPresented)
            
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
                    
                    Button {
                        SharedVars.shared.pendingNavigation = .walletPaymentCards
                        SharedVars.shared.selectedTab = 1
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "creditcard")
                                .padding(8)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Circle())
                                .padding(.trailing, 10)

                            Text("Payment Cards")
                                .foregroundStyle(Color(uiColor: .label))
                                .fontWeight(.medium)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    NavigationLink {
                        Text("Delete")
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .padding(8)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Circle())
                                .padding(.trailing, 10)
                            
                            Text("Delete History")
                                .foregroundStyle(.red.opacity(0.8))
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 8)

                    Button(role: .destructive) {
                        SharedVars.shared.logout()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .padding(8)
                                .background(Color.red.opacity(0.2))
                                .foregroundStyle(.red)
                                .clipShape(Circle())
                                .padding(.trailing, 10)

                            Text("Sign Out")
                                .foregroundStyle(.red)
                                .fontWeight(.medium)

                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSheet(isPresented: .constant(true))
    }
}
