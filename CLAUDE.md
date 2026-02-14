# Claude Development Guide
## RVU Tracker iOS - Medical Procedure RVU Management (Native iOS App)

This document guides Claude through working on the iOS version of RVU Tracker.

---

## Project Overview

Native iOS application for tracking medical procedure RVUs (Relative Value Units) with offline support, local caching, and seamless sync with the web application backend.

**Relationship to Web App:** Standalone iOS app that shares the same backend API and database with the Next.js web application. Users can access their data from either platform.

## Tech Stack

- **Platform:** iOS 17.0+ (iPhone only)
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)
- **Local Database:** Swift Data
- **Networking:** URLSession with modern async/await
- **Authentication:** Apple Sign-In + Google Sign-In
- **Dependency Manager:** Swift Package Manager (SPM)

## Project Structure

```
trackmyrvu/
├── trackmyrvuApp.swift              # App entry point
├── Date+Extensions.swift            # Date formatting utilities
├── Models/
│   ├── User.swift                   # User model (matches backend API)
│   ├── Visit.swift                  # Visit & VisitProcedure models (Codable, mutable for RVU enrichment)
│   └── Favorite.swift               # Favorite HCPCS code model
├── ViewModels/
│   ├── AuthViewModel.swift          # Authentication state (@Observable)
│   ├── VisitsViewModel.swift        # Visits list with caching + RVU enrichment
│   ├── EntryViewModel.swift         # New visit entry logic
│   ├── AnalyticsViewModel.swift     # Analytics calculations (client-side from visits)
│   └── FavoritesViewModel.swift     # Favorites CRUD with cancellation handling
├── Views/
│   ├── Auth/
│   │   └── SignInView.swift         # Google Sign-In screen
│   ├── Home/
│   │   └── HomeView.swift           # Tab navigation + home screen
│   ├── Visits/
│   │   └── VisitHistoryView.swift   # Visit list with swipe-to-delete
│   ├── Entry/
│   │   ├── NewVisitView.swift       # Visit creation/editing form
│   │   └── RVUSearchView.swift      # HCPCS code search
│   ├── Favorites/
│   │   └── FavoritesView.swift      # Favorites list with reorder
│   └── Analytics/
│       ├── AnalyticsView.swift      # Full analytics dashboard
│       ├── AnalyticsChartView.swift  # Bar chart + trend line (SwiftUI Charts)
│       ├── AnalyticsModels.swift     # ChartDataPoint, HCPCSBreakdownItem models
│       ├── StatCardsView.swift       # Summary stat cards (RVU, encounters, etc.)
│       └── HCPCSBreakdownView.swift  # HCPCS breakdown table by period
├── Services/
│   ├── APIService.swift             # Backend API client (actor, JWT Bearer auth)
│   ├── AuthService.swift            # Google Sign-In + Keychain JWT storage
│   └── RVUCacheService.swift        # Bundled CSV cache (16K HCPCS codes) + RVU enrichment
├── Resources/
│   ├── rvu.csv                      # Bundled HCPCS codes with work RVU values
│   └── Assets.xcassets/             # App icons, accent color
└── Info.plist                       # OAuth client IDs
```

## Core Features

### 1. Authentication ✅ IMPLEMENTED
- **Google Sign-In** - Fully implemented with backend JWT authentication
  - Uses GoogleSignIn-iOS SDK v9.1.0
  - Dual OAuth client IDs (iOS + Server)
  - Backend endpoint: `POST /api/auth/mobile/google`
  - JWT tokens (30-day expiration)
- **Apple Sign-In** - Not yet implemented (required for App Store)
- **Secure token storage** - iOS Keychain (not UserDefaults)
- **Session persistence** - Auto-restores on app launch
- **Token management** - Handles expiration, auto sign-out on 401
- **Shared user accounts** - Same backend as web application

### 2. Quick Visit Entry ✅ IMPLEMENTED
- Fast procedure logging on-the-go
- HCPCS code search with local cache (instant, works offline)
- Support for multiple procedures per visit
- Quantity adjustment per procedure
- Optional visit notes
- Auto-populated date/time (manual override available)
- Favorites for frequently used HCPCS codes
- Drag-to-reorder favorites

### 3. Visit History ✅ IMPLEMENTED
- List view of all visits (ordered by date DESC)
- Expandable procedure details
- Total RVU per visit (enriched from local CSV)
- Date and time display (12-hour format)
- Swipe-to-delete with confirmation
- Edit existing visits (add/remove procedures, update quantities)
- No-show visit tracking (orange badge)
- Pull-to-refresh
- Local caching with 5-minute expiration

### 4. Analytics Dashboard ✅ IMPLEMENTED
- Date range filtering (last 7/30/90 days, custom)
- Period grouping: Daily, Weekly, Monthly, Yearly
- RVU bar chart + trend line (SwiftUI Charts)
- HCPCS breakdown table (grouped by period)
- Summary stat cards: Total RVUs, Encounters, No Shows, Avg RVU/Encounter
- Client-side computation from visit data (no separate analytics API needed)

### 5. Favorites ✅ IMPLEMENTED
- Add/remove favorite HCPCS codes
- Drag-to-reorder with server sync
- Local cache with versioned invalidation
- Cancellation-safe loading (handles SwiftUI view recreation)

### 6. Offline Support (NOT YET IMPLEMENTED)
- All 16,852 HCPCS codes cached locally via bundled CSV
- Visit caching in UserDefaults (5-minute TTL)
- Full offline CRUD not yet implemented
- No sync service yet

## Data Models (Codable structs, not Swift Data)

### Visit Model
```swift
struct Visit: Codable, Identifiable {
    let id: String
    let userId: String
    let dateOfService: String      // "YYYY-MM-DD" or full ISO 8601
    let isNoShow: Bool
    let notes: String?
    var procedures: [VisitProcedure]  // mutable for RVU enrichment
    let createdAt: Date
    let updatedAt: Date

    var totalRVU: Double {
        procedures.reduce(0) { $0 + ($1.workRVU * Double($1.quantity)) }
    }
}

struct VisitProcedure: Codable, Identifiable {
    let id: String
    var visitId: String            // decodeIfPresent with default ""
    let hcpcs: String
    var description: String        // decodeIfPresent with default ""
    var statusCode: String         // decodeIfPresent with default ""
    var workRVU: Double            // mutable - enriched from local CSV
    let quantity: Int
}
```

### RVU Code Model
```swift
struct RVUCode: Codable, Identifiable, Hashable {
    let id: Int
    let hcpcs: String
    let description: String
    let statusCode: String
    let workRVU: Double
}
```

### Important: RVU Enrichment Pattern
The backend API returns `workRVU = 0` for procedures. The app enriches RVU values
from the bundled `rvu.csv` file via `RVUCacheService.enrichVisitsWithRVU(_:)`.
This enrichment runs after every API fetch in both `VisitsViewModel` and `AnalyticsViewModel`.

## API Integration

**Base URL:** `https://trackmyrvu.com/api`

### Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/visits` | GET | Fetch all visits for user |
| `/api/visits` | POST | Create new visit |
| `/api/visits/{id}` | PUT | Update existing visit |
| `/api/visits/{id}` | DELETE | Delete visit |
| `/api/analytics?period=...` | GET | Fetch analytics summary |
| `/api/analytics?groupBy=hcpcs` | GET | Fetch HCPCS breakdown |
| `/api/favorites` | GET | Fetch user favorites |
| `/api/favorites` | POST | Add favorite |
| `/api/favorites/{hcpcs}` | DELETE | Remove favorite |

### API Service Pattern

```swift
actor APIService {
    static let shared = APIService()
    private let baseURL = URL(string: "https://trackmyrvu.com/api")!

    func fetchVisits() async throws -> [VisitDTO] {
        let url = baseURL.appendingPathComponent("visits")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode([VisitDTO].self, from: data)
    }
}
```

## Offline Sync Strategy

### Sync Flow
1. **On App Launch:** Check network, sync if online
2. **On Network Change:** Auto-sync when connection restored
3. **Manual Trigger:** Pull-to-refresh or sync button
4. **Background Sync:** Periodic background fetch (if enabled)

### Conflict Resolution
- **Server Wins:** If visit modified on both client and server
- **Local Changes:** Reapply local changes on top of server version
- **Deleted Items:** Server deletions take precedence

### Sync States
- `synced` - Local matches server
- `pendingSync` - Local changes not yet uploaded
- `conflict` - Needs manual resolution

## Date Handling (CRITICAL)

**Same approach as web app:**
- All dates stored as `Date` in Swift Data
- Network requests use ISO 8601 strings (YYYY-MM-DD for dates)
- Display uses local timezone
- Server expects timezone-independent dates

```swift
// Date utilities
extension Date {
    var dateString: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }

    static func from(dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: dateString)
    }
}
```

## HCPCS Code Cache

### Implementation
- **Bundled Resource:** `rvu.csv` included in app bundle
- **On Load:** Parsed into `[RVUCode]` array and `[String: Double]` dictionary for O(1) HCPCS→RVU lookups
- **Search:** In-memory filter on `codes` array (case-insensitive, matches HCPCS or description)
- **Enrichment:** `enrichVisitsWithRVU(_:)` replaces procedure `workRVU` values from local cache
- **Singleton:** `RVUCacheService.shared`, must call `loadCodes()` before use

## Authentication Flow

### Apple Sign-In
1. User taps "Sign in with Apple"
2. iOS presents Apple Sign-In sheet
3. App receives identity token
4. Send token to backend `/api/auth/apple`
5. Backend validates, returns JWT
6. Store JWT in Keychain
7. Use JWT for all API requests

### Google Sign-In
1. User taps "Sign in with Google"
2. Present Google OAuth web view
3. Receive authorization code
4. Exchange for tokens via backend
5. Store JWT in Keychain

### Token Management
```swift
class AuthService {
    private let keychain = KeychainHelper.shared

    var authToken: String? {
        get { keychain.get(key: "authToken") }
        set {
            if let token = newValue {
                keychain.set(token, for: "authToken")
            } else {
                keychain.delete(key: "authToken")
            }
        }
    }

    func isTokenValid() -> Bool {
        // Check JWT expiration
    }

    func refreshToken() async throws {
        // Auto-refresh logic
    }
}
```

## SwiftUI Architecture

### MVVM Pattern
- **Models:** Codable structs (Visit, VisitProcedure, Favorite, RVUCode)
- **ViewModels:** `@Observable` classes (Swift 5.9 Observation macro, NOT ObservableObject)
- **Views:** SwiftUI views using `@State` for owned VMs
- **Services:** `actor APIService` (thread-safe), `RVUCacheService` (singleton)
- **Caching:** UserDefaults with versioned cache invalidation

## Dependencies (Swift Package Manager)

**Minimal dependencies approach:**
- **GoogleSignIn** - Google authentication (if needed)
- **KeychainAccess** - Secure token storage (optional, can use native Keychain)

**No third-party libraries for:**
- Networking (use native URLSession)
- UI (use SwiftUI)
- Database (use Swift Data)
- JSON (use Codable)

## Development Workflow

### Setup
```bash
# Clone repository
git clone <new-ios-repo-url>
cd rvu-tracker-ios

# Open in Xcode
open RVUTracker.xcodeproj

# Select target device/simulator
# Build and run (⌘R)
```

### Project Configuration
- **Bundle ID:** `trackmyrvuios.trackmyrvu`
- **Project Path:** `/Users/ddctu/git/track_my_rvu_ios/trackmyrvu/`
- **Xcode Project:** `trackmyrvu.xcodeproj`
- **Team:** Your Apple Developer Team
- **Deployment Target:** iOS 17.0+
- **Supported Devices:** iPhone only
- **Orientations:** Portrait only (lock landscape)
- **Dependencies:** GoogleSignIn-iOS v9.1.0 (via SPM)

### Testing Strategy
- **Unit Tests:** ViewModels, Services, Utilities
- **UI Tests:** Critical flows (sign in, create visit, sync)
- **Manual Testing:** Offline mode, sync conflicts, edge cases

## Backend Requirements

**Implemented Endpoints:**

1. **Google Mobile Auth** ✅
```typescript
// POST /api/auth/mobile/google
// Body: { idToken: string }
// Returns: { success: boolean, user: User, sessionToken: string, expiresIn: number }
// Reference: /Users/ddctu/git/hh/MOBILE_AUTH.md
```

**Endpoints Needed for Future Features:**

1. **Apple Sign-In endpoint**
```typescript
// POST /api/auth/apple
// Body: { identityToken: string, user?: { email, name } }
// Returns: { token: string, user: User }
```

2. **Bulk visits sync endpoint (optional optimization)**
```typescript
// POST /api/visits/sync
// Body: { lastSyncTimestamp: string, localChanges: Visit[] }
// Returns: { serverChanges: Visit[], conflicts: Visit[] }
```

**Backend Configuration:**
- Environment variable `GOOGLE_CLIENT_ID` must be set to: `386826311054-hic8jh474jh1aiq6dclp2oor9mgc981l.apps.googleusercontent.com`
- This is the Web/Server OAuth client ID used for token verification
- iOS app uses a different client ID for sign-in flow

## Conventions

- **Code Style:** Swift standard library conventions
- **Naming:** Descriptive, avoid abbreviations
- **Architecture:** MVVM with clear separation of concerns
- **State:** SwiftUI @State with @Observable ViewModels (NOT @StateObject/@ObservableObject)
- **Async:** Use async/await, avoid completion handlers
- **Error Handling:** Proper do-try-catch, user-friendly messages
- **Date Handling:** ALWAYS use timezone-independent utilities
- **Comments:** Explain "why" not "what", use doc comments for public APIs

## App Store Preparation

### App Metadata
- **Name:** RVU Tracker
- **Subtitle:** Track Medical Procedure RVUs
- **Category:** Medical
- **Privacy:** Requires Apple Sign-In disclosure

### Screenshots Required
- iPhone 6.7" (iPhone 15 Pro Max)
- iPhone 6.5" (iPhone 14 Plus)
- iPhone 5.5" (iPhone 8 Plus)

### App Icon
- 1024×1024 PNG (App Store)
- Generated assets for all sizes

## Current Status

**Core features implemented. Approaching App Store readiness.**

### Completed Features:
1. ✅ **Google Sign-In Authentication** - Full flow with backend JWT, Keychain storage, session persistence
2. ✅ **Visit History** - List view, swipe-to-delete, pull-to-refresh, local caching (5-min TTL)
3. ✅ **Visit Creation/Editing** - Multi-procedure support, HCPCS search, quantity, notes, no-show toggle
4. ✅ **Favorites** - Add/remove/reorder HCPCS favorites, versioned cache, cancellation-safe
5. ✅ **Analytics Dashboard** - Date range + period filtering, bar chart with trend line, stat cards, HCPCS breakdown
6. ✅ **RVU Enrichment** - Bundled CSV provides accurate work RVU values (API returns 0)
7. ✅ **HCPCS Code Search** - 16K+ codes cached locally from bundled CSV, instant search

### OAuth Configuration (Info.plist):
```xml
<key>GIDClientID</key>
<string>386826311054-ltu6cla9v0beb3k0p68o96ec5hfqv6ps.apps.googleusercontent.com</string>
<key>GIDServerClientID</key>
<string>386826311054-hic8jh474jh1aiq6dclp2oor9mgc981l.apps.googleusercontent.com</string>
```
- `GIDClientID` (iOS): Used for sign-in flow
- `GIDServerClientID` (Web): ID token audience for backend verification
- Backend endpoint: `POST /api/auth/mobile/google`

### Next Steps:
1. Implement Apple Sign-In (required for App Store)
2. Implement full offline support with Swift Data
3. Build sync service for offline changes
4. Testing and polish
5. App Store submission

### Known Issues:
- Backend API returns `workRVU = 0` for procedures; app enriches from local CSV
- No offline CRUD yet (reads work offline via cache, writes require network)
- Date parsing handles both `YYYY-MM-DD` and full ISO 8601 formats from backend

---

## When Working on This Project

1. **Mobile-first thinking** - Optimize for quick entry, one-handed use
2. **Offline-first** - Every feature must work without internet
3. **Type safety** - Leverage Swift's type system, avoid force unwraps
4. **SwiftUI native** - Use platform conventions, avoid web app patterns
5. **Date handling** - Use timezone-independent utilities from day one
6. **Test offline** - Always test airplane mode, sync conflicts
7. **Update this doc** - Keep CLAUDE.md current with implementation decisions
