//
//  SignInView.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import SwiftUI
import GoogleSignInSwift

/// Google Sign-In authentication screen
struct SignInView: View {
    @Bindable var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App branding
                VStack(spacing: 20) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)

                    Text("RVU Tracker")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Track Medical Procedure RVUs")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Google Sign-In button
                VStack(spacing: 16) {
                    GoogleSignInButton(action: {
                        Task {
                            await authViewModel.signIn()
                        }
                    })
                    .frame(height: 50)
                    .padding(.horizontal, 40)

                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.blue)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .alert(
            "Sign-In Error",
            isPresented: Binding(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let error = authViewModel.errorMessage {
                Text(error)
            }
        }
    }
}

#Preview {
    SignInView(authViewModel: AuthViewModel())
}
