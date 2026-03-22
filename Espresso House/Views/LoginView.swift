//
//  LoginView.swift
//  Espresso House
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.brown)

                Text("Espresso House")
                    .font(.largeTitle.bold())

                switch viewModel.state {
                case .phoneEntry:
                    phoneEntryView
                case .loading(let message):
                    loadingView(message: message)
                case .smsEntry:
                    smsEntryView
                case .error(let message):
                    errorView(message: message)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }

    private var phoneEntryView: some View {
        VStack(spacing: 20) {
            Text("Enter your phone number")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("🇸🇪 +46")
                    .font(.body.monospaced())
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("7XXXXXXXX", text: $viewModel.phoneNumber)
                    .keyboardType(.phonePad)
                    .font(.body.monospaced())
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                Task { await viewModel.submitPhone() }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown)
            .disabled(viewModel.phoneNumber.isEmpty)
        }
    }

    private func loadingView(message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .foregroundStyle(.secondary)
        }
    }

    private var smsEntryView: some View {
        VStack(spacing: 20) {
            Text("Enter the code from SMS")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField("Code", text: $viewModel.smsCode)
                .keyboardType(.numberPad)
                .font(.title2.monospaced())
                .multilineTextAlignment(.center)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                Task { await viewModel.submitSMSCode() }
            } label: {
                Text("Verify")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown)
            .disabled(viewModel.smsCode.isEmpty)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.red)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown)
        }
    }
}
