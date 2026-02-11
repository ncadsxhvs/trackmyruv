//
//  DebugFavoritesView.swift
//  trackmyrvu
//
//  Debug view to test favorites loading
//

import SwiftUI

struct DebugFavoritesView: View {
    @State private var testResult = "Tap 'Test API' to start"
    @State private var isLoading = false
    @State private var favoritesList: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Test Button
                Button {
                    Task {
                        await testFavoritesAPI()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Image(systemName: "arrow.clockwise")
                        Text(isLoading ? "Testing..." : "Test Favorites API")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                // Test Result
                GroupBox("Test Result") {
                    ScrollView {
                        Text(testResult)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 400)
                }

                // Favorites List
                if !favoritesList.isEmpty {
                    GroupBox("Favorites (\(favoritesList.count))") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(favoritesList, id: \.self) { hcpcs in
                                Text(hcpcs)
                                    .font(.headline)
                                Divider()
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Debug Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testFavoritesAPI() async {
        isLoading = true
        testResult = ""
        favoritesList = []

        var output = "🔍 Starting Favorites API Test\n"
        output += String(repeating: "=", count: 40) + "\n\n"

        // Step 1: Check auth token
        output += "1️⃣ Checking Auth Token...\n"
        guard let token = await MainActor.run(body: { AuthService.shared.loadTokenFromKeychain() }) else {
            output += "   ❌ FAILED: No auth token in keychain\n"
            output += "   → Sign out and sign back in\n"
            testResult = output
            isLoading = false
            return
        }
        output += "   ✅ Token found: \(token.prefix(30))...\n\n"

        // Step 2: Make API call
        output += "2️⃣ Calling GET /api/favorites...\n"
        output += "   URL: https://www.trackmyrvu.com/api/favorites\n"

        do {
            // Make raw URLRequest to see response
            let url = URL(string: "https://www.trackmyrvu.com/api/favorites")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            output += "   ❌ Not an HTTP response\n"
            testResult = output
            isLoading = false
            return
        }

        output += "   📡 Status: \(httpResponse.statusCode)\n"

        if let jsonString = String(data: data, encoding: .utf8) {
            output += "   📦 RAW JSON:\n"
            output += "   \(jsonString)\n\n"
        }

            guard httpResponse.statusCode == 200 else {
                output += "   ❌ HTTP Error \(httpResponse.statusCode)\n"
                testResult = output
                isLoading = false
                return
            }

            // Try to decode the response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            let favorites = try decoder.decode([Favorite].self, from: data)

            output += "   ✅ API call succeeded!\n"
            output += "   📊 Status: 200 OK\n"
            output += "   📦 Received: \(favorites.count) favorites\n\n"

            if favorites.isEmpty {
                output += "⚠️  No favorites found\n"
                output += "   → Add favorites from search view\n"
                output += "   → Or add via web app\n"
            } else {
                output += "3️⃣ Favorites Data:\n"
                for (index, fav) in favorites.enumerated() {
                    output += "   \(index + 1). \(fav.hcpcs)\n"
                    output += "      User ID: \(fav.userId)\n"
                    output += "      Sort Order: \(fav.sortOrder)\n"
                    favoritesList.append(fav.hcpcs)
                }
                output += "\n✅ All favorites loaded successfully!\n"
            }
        } catch let decodingError as DecodingError {
            output += "   ❌ DECODING ERROR:\n"
            output += "   → \(decodingError.localizedDescription)\n"
            output += "\n🐛 Backend response doesn't match iOS model\n"
        } catch {
            output += "   ❌ Network or Unknown Error:\n"
            output += "   → \(error.localizedDescription)\n"
            output += "   → Check internet connection\n"
        }

        testResult = output
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        DebugFavoritesView()
    }
}
