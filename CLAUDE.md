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

**Actual Structure (Current Implementation):**
```
trackmyrvu/
├── trackmyrvuApp.swift          # App entry point
├── Models/
│   ├── User.swift               # User model (matches backend API)
│   └── Visit.swift              # Visit & VisitProcedure models
├── ViewModels/
│   ├── AuthViewModel.swift      # Authentication state (@Observable)
│   └── VisitsViewModel.swift    # Visits list loading logic
├── Views/
│   ├── Auth/
│   │   └── SignInView.swift     # Google Sign-In screen
│   ├── Home/
│   │   └── HomeView.swift       # Authenticated home screen
│   └── Visits/
│       └── VisitHistoryView.swift # Visit list view
├── Services/
│   ├── AuthService.swift        # Google Sign-In + JWT auth
│   └── APIService.swift         # Backend API client (JWT tokens)
└── Info.plist                   # OAuth client IDs
```

**Planned Structure (Future):**
```
trackmyrvu/
├── trackmyrvuApp.swift         # App entry point
├── Models/
│   ├── Visit.swift             # Visit data model (Swift Data)
│   ├── Procedure.swift          # Procedure data model
│   ├── RVUCode.swift           # HCPCS code model
│   └── User.swift              # User model
├── ViewModels/
│   ├── VisitsViewModel.swift   # Visits list & CRUD logic
│   ├── EntryViewModel.swift    # New visit entry logic
│   ├── AnalyticsViewModel.swift # Analytics calculations
│   └── AuthViewModel.swift     # Authentication logic
├── Views/
│   ├── ContentView.swift       # Main tab navigation
│   ├── VisitsList/
│   │   ├── VisitsListView.swift
│   │   └── VisitRowView.swift
│   ├── Entry/
│   │   ├── EntryView.swift
│   │   ├── RVUSearchView.swift
│   │   └── FavoritesView.swift
│   ├── Analytics/
│   │   ├── AnalyticsView.swift
│   │   └── ChartView.swift
│   └── Auth/
│       └── SignInView.swift
├── Services/
│   ├── APIService.swift        # Backend API client
│   ├── SyncService.swift       # Offline sync logic
│   ├── RVUCacheService.swift   # Local HCPCS cache (16K codes)
│   └── AuthService.swift       # Auth token management
├── Utilities/
│   ├── DateUtils.swift         # Timezone-independent dates
│   ├── Constants.swift         # App constants
│   └── Extensions/
│       ├── Date+Extensions.swift
│       └── View+Extensions.swift
└── Resources/
    ├── Assets.xcassets
    └── rvu_codes.json          # Bundled HCPCS codes (16K)
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

### 2. Quick Visit Entry (Primary Mobile Use Case)
- Fast procedure logging on-the-go
- HCPCS code search with local cache (instant, works offline)
- Support for multiple procedures per visit
- Quantity adjustment per procedure
- Optional visit notes
- Auto-populated date/time (manual override available)
- Favorites for frequently used HCPCS codes
- Drag-to-reorder favorites

### 3. Visit History
- List view of all visits (ordered by date DESC)
- Expandable procedure details
- Total RVU per visit
- Date and time display (12-hour format)
- Swipe-to-delete with confirmation
- Edit existing visits (add/remove procedures, update quantities)
- Copy visit to create similar entry
- No-show visit tracking (orange badge)
- Pull-to-refresh

### 4. Analytics Dashboard
- Date range filtering (last 7/30/90 days, custom)
- Period grouping: Daily, Weekly, Monthly, Yearly
- RVU chart over time (SwiftUI Charts)
- HCPCS breakdown table (grouped by date)
- Summary metrics:
  - Total RVUs
  - Total Encounters
  - Total No Shows
  - Average RVU per Encounter
- Export analytics as PDF (share sheet)

### 5. Offline Support
- **Local-first architecture**
- All visits stored in Swift Data
- All 16,852 HCPCS codes cached locally (~5MB)
- Create/edit/delete visits offline
- Automatic sync when online
- Conflict resolution (server wins, local changes merged)
- Sync status indicator
- Manual sync trigger

## Data Models (Swift Data)

### Visit Model
```swift
@Model
final class Visit {
    @Attribute(.unique) var id: UUID
    var userId: String
    var date: Date
    var time: Date?
    var notes: String?
    var isNoShow: Bool
    @Relationship(deleteRule: .cascade) var procedures: [Procedure]
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus // .synced, .pendingSync, .conflict

    var totalRVU: Double {
        procedures.reduce(0) { $0 + ($1.workRVU * Double($1.quantity)) }
    }
}

@Model
final class Procedure {
    var id: UUID
    var hcpcs: String
    var description: String
    var statusCode: String
    var workRVU: Double
    var quantity: Int
    var visit: Visit?
}
```

### RVU Code Model
```swift
struct RVUCode: Codable, Identifiable {
    let id: Int
    let hcpcs: String
    let description: String
    let statusCode: String
    let workRVU: Double
}
```

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
- **Bundled Resource:** `rvu_codes.json` included in app bundle (~5MB)
- **First Launch:** Load into Swift Data for fast search
- **Search:** Local query using Swift Data predicates
- **Update:** Periodic check for RVU code updates from server

```swift
@MainActor
class RVUCacheService: ObservableObject {
    static let shared = RVUCacheService()

    @Published var isLoaded = false

    func loadCodes() async throws {
        guard let url = Bundle.main.url(forResource: "rvu_codes", withExtension: "json") else {
            throw CacheError.resourceNotFound
        }

        let data = try Data(contentsOf: url)
        let codes = try JSONDecoder().decode([RVUCode].self, from: data)

        // Store in UserDefaults or Swift Data for fast search
        // Implementation details...

        isLoaded = true
    }

    func search(query: String, limit: Int = 100) -> [RVUCode] {
        // Fast local search implementation
    }
}
```

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
- **Models:** Swift Data entities (Visit, Procedure)
- **ViewModels:** ObservableObject classes with @Published properties
- **Views:** SwiftUI views that observe ViewModels

### Example: Visits List

```swift
@MainActor
class VisitsViewModel: ObservableObject {
    @Published var visits: [Visit] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let apiService = APIService.shared
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchVisits() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Try API first
            let dtos = try await apiService.fetchVisits()
            // Update local database
            // Fetch from Swift Data
            let descriptor = FetchDescriptor<Visit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            visits = try modelContext.fetch(descriptor)
        } catch {
            // Fall back to local data if offline
            self.error = error
            loadLocalVisits()
        }
    }

    func deleteVisit(_ visit: Visit) async {
        modelContext.delete(visit)
        try? modelContext.save()

        // Sync deletion to server
        Task {
            try? await apiService.deleteVisit(id: visit.id)
        }
    }
}
```

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
- **State:** SwiftUI @State, @StateObject, @EnvironmentObject
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

**✅ AUTHENTICATION IMPLEMENTED - IN PROGRESS**

### Completed Features:

#### 1. **Google Sign-In Authentication** ✅
- **Location**: `/Users/ddctu/git/track_my_rvu_ios/trackmyrvu/`
- **Bundle ID**: `trackmyrvuios.trackmyrvu`
- **Backend**: Production API at `https://www.trackmyrvu.com/api`

**Implementation Details:**
- **AuthService.swift**: Complete mobile authentication flow
  - Google Sign-In → ID token exchange → Backend JWT token
  - JWT stored securely in iOS Keychain (not UserDefaults)
  - Session restoration on app launch
  - Token expiration handling (30-day tokens)

- **User Model**: Matches backend API response
  - Fields: `id`, `email`, `name?`, `image?`
  - Codable for JSON serialization
  - Computed properties: `displayName`, `profileImageURL`

- **AuthViewModel**: Observable authentication state (@Observable)
  - Properties: `currentUser`, `sessionToken`, `isLoading`, `errorMessage`
  - Methods: `signIn()`, `signOut()`, `checkAuthStatus()`
  - Session persistence across app restarts

- **APIService**: JWT Bearer token authentication
  - All requests include `Authorization: Bearer <token>` header
  - Automatic token retrieval from Keychain
  - Handles 401 (token expired) errors

**OAuth Configuration (Info.plist):**
```xml
<key>GIDClientID</key>
<string>386826311054-ltu6cla9v0beb3k0p68o96ec5hfqv6ps.apps.googleusercontent.com</string>
<key>GIDServerClientID</key>
<string>386826311054-hic8jh474jh1aiq6dclp2oor9mgc981l.apps.googleusercontent.com</string>
```

**Why Two Client IDs:**
- `GIDClientID` (iOS): Used for sign-in flow (supports custom URL schemes)
- `GIDServerClientID` (Web): ID token audience for backend verification
- Backend verifies tokens using the server/web client ID

**Backend Endpoint Used:**
- `POST /api/auth/mobile/google` - Exchanges Google ID token for JWT
- Reference: `/Users/ddctu/git/hh/MOBILE_AUTH.md`

#### 2. **UI Views** ✅
- **SignInView**: Google Sign-In button, loading states, error handling
- **HomeView**: Profile display, RVU summary cards (placeholders), quick actions
- **VisitHistoryView**: List of visits with procedures (ready for API data)

#### 3. **API Integration** ✅
- **APIService**: Configured for production backend
- **VisitsViewModel**: Fetches visits from `/api/visits` endpoint
- **Visit Model**: Matches backend schema with procedures

### In Progress:

- Visit history data fetching (API ready, needs testing)
- Error handling and retry logic
- Offline mode (not yet implemented)

### Next Steps:
1. ~~Implement authentication (Google Sign-In)~~ ✅
2. Test end-to-end authentication flow
3. Implement visit creation (POST /api/visits)
4. Add visit editing and deletion
5. Implement offline support with Swift Data
6. Build analytics dashboard
7. Implement sync service for offline changes
8. Bundle HCPCS codes (~5MB JSON)
9. Implement Apple Sign-In (App Store requirement)
10. Testing and polish
11. App Store submission

### Known Issues:
- None currently - authentication working as expected

---

## When Working on This Project

1. **Mobile-first thinking** - Optimize for quick entry, one-handed use
2. **Offline-first** - Every feature must work without internet
3. **Type safety** - Leverage Swift's type system, avoid force unwraps
4. **SwiftUI native** - Use platform conventions, avoid web app patterns
5. **Date handling** - Use timezone-independent utilities from day one
6. **Test offline** - Always test airplane mode, sync conflicts
7. **Update this doc** - Keep CLAUDE.md current with implementation decisions
