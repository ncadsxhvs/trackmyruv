# 🔧 BUILD FIX - Copy & Paste This Code

## Step 1: Replace AnalyticsViewModel.swift

**Delete current content and paste this:**

```swift
//
//  AnalyticsViewModel.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-12.
//

import Foundation
import SwiftUI

/// Simple analytics - calculates total RVU from cached visits
@Observable
@MainActor
class AnalyticsViewModel {
    // MARK: - Computed Properties
    
    /// Total RVU from all cached visits
    var totalRVUs: Double {
        visitsViewModel.visits.reduce(0.0) { sum, visit in
            sum + visit.totalWorkRVU
        }
    }
    
    /// Number of visits
    var visitCount: Int {
        visitsViewModel.visits.count
    }
    
    /// Number of encounters (non-no-shows)
    var encounterCount: Int {
        visitsViewModel.visits.filter { !$0.isNoShow }.count
    }
    
    /// Number of no-shows
    var noShowCount: Int {
        visitsViewModel.visits.filter { $0.isNoShow }.count
    }
    
    // MARK: - Dependencies
    
    private let visitsViewModel: VisitsViewModel
    
    // MARK: - Initialization
    
    init(visitsViewModel: VisitsViewModel) {
        self.visitsViewModel = visitsViewModel
        print("📊 [Analytics] Initialized with \(visitsViewModel.visits.count) cached visits")
    }
}
```

---

## Step 2: Replace AnalyticsView.swift

**Delete current content and paste this:**

```swift
//
//  AnalyticsView.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-12.
//

import SwiftUI

/// Simple analytics view showing total RVU
struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel
    
    init(visitsViewModel: VisitsViewModel) {
        _viewModel = State(initialValue: AnalyticsViewModel(visitsViewModel: visitsViewModel))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Total RVU Card
                totalRVUCard
                
                // Stats Cards
                statsGrid
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Total RVU Card
    
    private var totalRVUCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.gradient)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Total RVUs")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(String(format: "%.2f", viewModel.totalRVUs))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: Color.blue.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Total Visits",
                value: "\(viewModel.visitCount)",
                icon: "calendar",
                color: .green
            )
            
            StatCard(
                title: "Encounters",
                value: "\(viewModel.encounterCount)",
                icon: "person.2",
                color: .purple
            )
            
            StatCard(
                title: "No Shows",
                value: "\(viewModel.noShowCount)",
                icon: "exclamationmark.triangle",
                color: .orange
            )
            
            StatCard(
                title: "Avg RVU/Visit",
                value: viewModel.visitCount > 0 ? String(format: "%.2f", viewModel.totalRVUs / Double(viewModel.visitCount)) : "0.00",
                icon: "chart.bar",
                color: .pink
            )
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnalyticsView(visitsViewModel: VisitsViewModel())
    }
}
```

---

## Step 3: Delete These Files (If They Exist)

In Xcode Project Navigator, delete:
- AnalyticsView 3.swift
- AnalyticsView 5.swift
- AnalyticsView 6.swift
- AnalyticsView 9.swift
- AnalyticsViewModel 2.swift
- AnalyticsData.swift (not needed anymore)
- AnalyticsTestView.swift

---

## Step 4: Verify HomeView.swift

Make sure HomeView has this code for Analytics:

```swift
case "analytics":
    AnalyticsView(visitsViewModel: visitsViewModel)
```

And in HomeView's body:

```swift
@State private var visitsViewModel = VisitsViewModel()

// ... in the view body ...

.task {
    await visitsViewModel.loadVisits()
}
```

---

## Step 5: Clean & Build

```
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Wait for clean to complete
3. Product → Build (Cmd+B)
4. Should succeed with 0 errors
```

---

## If Build Still Fails

### Error: "Cannot find AnalyticsViewModel"
- Make sure you saved the file after pasting
- Make sure file is added to target (check file inspector)

### Error: "Duplicate symbol"
- Delete all numbered duplicate files (3, 5, 6, 9, 2)
- Clean derived data: Xcode → Preferences → Locations → Derived Data → Delete

### Error: "Cannot find VisitsViewModel"
- File exists, just needs import or target membership

---

**After successful build, run the app and test analytics!** 🚀
