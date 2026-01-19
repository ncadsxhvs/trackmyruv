//
//  SignInView.swift
//  RVU Tracker
//
//  Sign-in screen with Apple and Google Sign-In options
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("PrimaryColor").opacity(0.1),
                    Color("SecondaryColor").opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("PrimaryColor"))

                    Text("RVU Tracker")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))

                    Text("Track your medical procedures and RVUs")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Sign-In Buttons
                VStack(spacing: 16) {
                    // Apple Sign-In Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            // Configuration handled by AuthViewModel
                        },
                        onCompletion: { _ in
                            // Handled by AuthViewModel delegate
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    .onTapGesture {
                        viewModel.signInWithApple()
                    }

                    // Google Sign-In Button
                    Button(action: {
                        viewModel.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)

                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)

                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }

                Spacer()

                // Privacy Notice
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))

                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // TODO: Open terms of service
                        }
                        .font(.caption)
                        .foregroundColor(Color("PrimaryColor"))

                        Text("and")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))

                        Button("Privacy Policy") {
                            // TODO: Open privacy policy
                        }
                        .font(.caption)
                        .foregroundColor(Color("PrimaryColor"))
                    }
                }
                .padding(.bottom, 32)
            }

            // Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignInView()
}

#Preview("Loading") {
    SignInView()
}

#Preview("With Error") {
    SignInView()
}
