//
//  CartSheet.swift
//  Espresso House
//

import SwiftUI
import Kingfisher

struct CartSheet: View {
    @Bindable var cart: CartViewModel
    @Environment(\.dismiss) private var dismiss

    var onCheckout: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if cart.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("Your cart is empty")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(cart.items) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    if let imgUrl = item.product.img, let url = URL(string: imgUrl) {
                                        KFImage(url)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.product.articleName)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                        if item.sizeName != "Standard" {
                                            Text(item.sizeName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let upsells = item.product.upsell?.filter({ $0.selected }), !upsells.isEmpty {
                                            Text(upsells.map { "+ \($0.articleName)" }.joined(separator: ", "))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()
                                }

                                // Quantity + price row
                                HStack {
                                    HStack(spacing: 14) {
                                        Button {
                                            withAnimation {
                                                if item.quantity > 1 {
                                                    cart.updateQuantity(id: item.id, quantity: item.quantity - 1)
                                                } else {
                                                    cart.removeItem(id: item.id)
                                                }
                                            }
                                        } label: {
                                            Image(systemName: item.quantity <= 1 ? "trash" : "minus")
                                                .contentTransition(.symbolEffect(.replace))
                                                .font(.system(size: 13, weight: .semibold))
                                                .frame(width: 28, height: 28)
                                                .background(Color(.systemGray5))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)

                                        Text("\(item.quantity)")
                                            .fontWeight(.semibold)
                                            .monospacedDigit()

                                        Button {
                                            cart.updateQuantity(id: item.id, quantity: item.quantity + 1)
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 13, weight: .semibold))
                                                .frame(width: 28, height: 28)
                                                .background(Color(.systemGray5))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    Spacer()

                                    Text("\(Int(item.totalPrice)) \(cart.currency)")
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                cart.removeItem(id: cart.items[index].id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cart (\(cart.totalItems))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !cart.isEmpty {
                        Button {
                            cart.clear()
                        } label: {
                            Text("Clear")
                                .foregroundStyle(.red)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !cart.isEmpty {
                    Button {
                        dismiss()
                        onCheckout()
                    } label: {
                        HStack {
                            Text("Checkout")
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(Int(cart.totalPrice)) \(cart.currency)")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
