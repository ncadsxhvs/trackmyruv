//
//  trackmyrvuApp.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import SwiftUI
import GoogleSignIn

@main
struct trackmyrvuApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isSignedIn {
                    HomeView(authViewModel: authViewModel)
                } else {
                    SignInView(authViewModel: authViewModel)
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
