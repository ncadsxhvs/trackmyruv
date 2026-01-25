# RVU Tracker iOS - Project Planning Document

**Version:** 1.0.0
**Platform:** iOS 17.0+
**Status:** In Development - Phase 1 Complete
**Last Updated:** January 25, 2026

---

## 🎉 Phase 1 Complete: Authentication & Home Screen

**Completed:** January 25, 2026

### Implementation Summary

Successfully implemented Google Sign-In authentication with a dedicated login page and authenticated home screen. The app now has:

#### Project Structure Created
```
trackmyrvu/
├── Info.plist                          # Google OAuth configuration
├── trackmyrvu.xcodeproj/               # Xcode project
└── trackmyrvu/                         # Source files
    ├── Models/
    │   └── User.swift                  # User data model
    ├── Services/
    │   └── AuthService.swift           # Google Sign-In integration
    ├── ViewModels/
    │   └── AuthViewModel.swift         # Authentication state management
    ├── Views/
    │   ├── Auth/
    │   │   └── SignInView.swift        # Login screen
    │   └── Home/
    │       └── HomeView.swift          # Authenticated home screen
    ├── Assets.xcassets/                # App assets
    ├── Preview Content/                # Preview assets
    └── trackmyrvuApp.swift             # App entry point
```

#### Files Implemented

1. **User.swift** - Codable struct for user profile data with properties: id, email, name, profileImageURL, givenName, familyName

2. **AuthService.swift** - Google Sign-In SDK integration with methods:
   - `signIn()` - Trigger Google authentication flow
   - `signOut()` - Clear Google session
   - `restorePreviousSignIn()` - Auto-restore session
   - User data persistence via UserDefaults

3. **AuthViewModel.swift** - Observable state manager using @Observable macro:
   - Properties: currentUser, isLoading, errorMessage, isSignedIn
   - Automatic session restoration on init
   - Async sign-in/sign-out methods

4. **SignInView.swift** - Branded login screen featuring:
   - Medical app branding with heart icon
   - Native GoogleSignInSwift button
   - Loading state indicator
   - Error alert handling

5. **HomeView.swift** - Authenticated home screen with:
   - Profile header with AsyncImage for Google photo
   - RVU summary cards (placeholders ready for Phase 7)
   - Quick action buttons for future features:
     - New Visit Entry (→ Phase 3)
     - Visit History (→ Phase 4)
     - Analytics (→ Phase 7)
   - Sign-out confirmation dialog

6. **trackmyrvuApp.swift** - App entry point with:
   - Conditional navigation based on auth state
   - Google OAuth URL callback handler
   - Single AuthViewModel instance for app lifetime

7. **Info.plist** - OAuth configuration:
   - GIDClientID: 386826311054-ltu6cla9v0beb3k0p68o96ec5hfqv6ps.apps.googleusercontent.com
   - CFBundleURLTypes for OAuth callback URL scheme

#### Configuration

- **GoogleSignIn SDK**: Version 9.1.0 (via Swift Package Manager)
- **Client ID**: 386826311054-ltu6cla9v0beb3k0p68o96ec5hfqv6ps.apps.googleusercontent.com
- **URL Scheme**: com.googleusercontent.apps.386826311054-ltu6cla9v0beb3k0p68o96ec5hfqv6ps
- **Bundle ID**: trackmyrvuios.trackmyrvu
- **iOS Deployment Target**: iOS 26.2 (can be lowered to 17.0 if needed)

#### Build Status

**Build Command:**
```bash
cd /Users/ddctu/git/track_my_rvu_ios/trackmyrvu
xcodebuild build -scheme trackmyrvu \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug
```

**Result:** ✅ BUILD SUCCEEDED

#### Key Features Working

1. **Google Sign-In Authentication**
   - Native GoogleSignInSwift button integration
   - Automatic session restoration on app launch
   - Secure token management via GoogleSignIn SDK

2. **Conditional Navigation**
   - SignInView displayed for unauthenticated users
   - HomeView displayed for authenticated users
   - Automatic navigation on auth state changes

3. **Profile Display**
   - User name and email from Google profile
   - Profile photo with AsyncImage (with fallback icon)
   - Material design UI elements

4. **Modern Architecture**
   - @Observable for state management (iOS 17+)
   - Swift Concurrency (async/await)
   - SwiftUI with native UI components

5. **User Experience**
   - Loading states during sign-in
   - Error handling with alerts
   - Sign-out confirmation dialog
   - Gradient background on login screen

#### Next Steps

The HomeView contains placeholder buttons ready for:
- **Phase 3**: Quick Visit Entry implementation
- **Phase 4**: Visit History list view
- **Phase 7**: Analytics Dashboard

All authentication infrastructure is complete and ready for building the core RVU tracking features.

---

## Project Overview

Native iOS application for tracking medical procedure RVUs (Relative Value Units) with offline-first architecture, local caching, and seamless synchronization with the existing Next.js web application backend at https://trackmyrvu.com.

### Key Objectives

- **Mobile-optimized UX** - Fast, one-handed procedure entry on-the-go
- **Offline-first** - Full functionality without internet connection
- **Cross-platform sync** - Share data seamlessly with web application
- **App Store ready** - Production-quality, compliant with Apple guidelines

---

## Version Information

### Version 1.0.0 (MVP)
**Target Release:** TBD  
**Core Features:**
- Apple & Google Sign-In
- Quick visit entry with HCPCS search
- Visit history with edit/delete
- Basic analytics dashboard
- Offline support with automatic sync
- Favorites management

### Future Versions
- **v1.1.0** - iPad support, landscape mode
- **v1.2.0** - Enhanced analytics, custom date ranges
- **v1.3.0** - Widgets, Siri shortcuts
- **v2.0.0** - Apple Watch companion app

---

## Architecture

### Design Pattern
**MVVM (Model-View-ViewModel)**

```
┌─────────────────────────────────────────┐
│              SwiftUI Views              │
│  (ContentView, EntryView, Analytics)    │
└──────────────┬──────────────────────────┘
               │ Observes @Published
┌──────────────▼──────────────────────────┐
│           ViewModels                    │
│  (VisitsVM, EntryVM, AnalyticsVM)       │
└──────────────┬──────────────────────────┘
               │ Uses
┌──────────────▼──────────────────────────┐
│            Services                     │
│  (APIService, SyncService, AuthService) │
└──────────────┬──────────────────────────┘
               │ Reads/Writes
┌──────────────▼──────────────────────────┐
│         Swift Data Models               │
│      (Visit, Procedure, RVUCode)        │
└─────────────────────────────────────────┘
```

### Data Flow

1. **User Interaction** → SwiftUI View
2. **View** → Calls ViewModel method
3. **ViewModel** → Interacts with Services
4. **Services** → API calls + Local database operations
5. **Services** → Returns data to ViewModel
6. **ViewModel** → Updates @Published properties
7. **View** → Auto-refreshes via SwiftUI

### Offline-First Strategy

```
Local Database (Swift Data) = Source of Truth
       ↓
   User Action
       ↓
  Save Locally (immediate)
       ↓
  Mark as "pending sync"
       ↓
  When online → Sync to server
       ↓
  Update sync status → "synced"
```

---

## Technology Stack

### Core Technologies

| Component | Technology | Version |
|-----------|------------|---------|
| **Language** | Swift | 5.9+ |
| **UI Framework** | SwiftUI | iOS 17+ |
| **Database** | Swift Data | iOS 17+ |
| **Networking** | URLSession | Native |
| **JSON** | Codable | Native |
| **Authentication** | AuthenticationServices | Native |
| **Charts** | Swift Charts | iOS 16+ |

### Third-Party Dependencies (SPM)

| Package | Purpose | Optional |
|---------|---------|----------|
| `GoogleSignIn-iOS` | Google OAuth | No |
| `KeychainAccess` | Secure storage | Yes (can use native) |

### Backend Integration

- **API Base:** `https://trackmyrvu.com/api`
- **Auth:** JWT Bearer tokens
- **Format:** JSON (REST)
- **Shared Database:** PostgreSQL (via web app)

### Apple Frameworks

- **AuthenticationServices** - Apple Sign-In
- **Security** - Keychain storage
- **BackgroundTasks** - Background sync
- **PDFKit** - Analytics export
- **Combine** - Reactive programming (minimal use)

---

## Project Structure

```
RVUTracker/
├── RVUTrackerApp.swift              # App entry point
│
├── Models/                          # Swift Data models
│   ├── Visit.swift                  # @Model class
│   ├── Procedure.swift              # @Model class
│   ├── RVUCode.swift                # Struct (cached)
│   └── User.swift                   # User profile
│
├── ViewModels/                      # Business logic
│   ├── VisitsViewModel.swift        # Visit CRUD + list
│   ├── EntryViewModel.swift         # New visit creation
│   ├── AnalyticsViewModel.swift     # Analytics calculations
│   └── AuthViewModel.swift          # Auth state management
│
├── Views/                           # SwiftUI views
│   ├── ContentView.swift            # Tab navigation
│   │
│   ├── VisitsList/
│   │   ├── VisitsListView.swift     # Main list
│   │   └── VisitRowView.swift       # List item
│   │
│   ├── Entry/
│   │   ├── EntryView.swift          # Quick entry form
│   │   ├── RVUSearchView.swift      # HCPCS search
│   │   └── FavoritesView.swift      # Favorites picker
│   │
│   ├── Analytics/
│   │   ├── AnalyticsView.swift      # Dashboard
│   │   └── ChartView.swift          # RVU chart
│   │
│   └── Auth/
│       └── SignInView.swift         # Login screen
│
├── Services/                        # Business services
│   ├── APIService.swift             # HTTP client
│   ├── SyncService.swift            # Offline sync logic
│   ├── RVUCacheService.swift        # Local HCPCS cache
│   └── AuthService.swift            # Token management
│
├── Utilities/                       # Helpers
│   ├── DateUtils.swift              # Timezone-safe dates
│   ├── Constants.swift              # App constants
│   └── Extensions/
│       ├── Date+Extensions.swift
│       └── View+Extensions.swift
│
├── Resources/                       # Assets
│   ├── Assets.xcassets              # Images, colors
│   └── rvu_codes.json               # 16K HCPCS codes (~5MB)
│
└── Tests/
    ├── RVUTrackerTests/             # Unit tests
    └── RVUTrackerUITests/           # UI tests
```

---

## Development Roadmap

### Phase 1: Foundation (Week 1-2) ✅ COMPLETE
**Goal:** Project setup, authentication, basic navigation

#### Setup Tasks
- [x] Create new Xcode project (iOS 17+, iPhone only)
- [x] Configure bundle ID: `trackmyrvuios.trackmyrvu`
- [x] Add Swift Package dependencies (GoogleSignIn v9.1.0)
- [x] Set up Git repository
- [x] Configure app icons and launch screen (basic assets)
- [ ] Set up development/production schemes (deferred)

#### Authentication
- [x] Implement `AuthService` with secure storage (via GoogleSignIn SDK)
- [x] Create `SignInView` UI
- [ ] Integrate Apple Sign-In (deferred to Phase 1.5)
- [x] Integrate Google Sign-In
- [x] Implement session management (Google tokens)
- [x] Add auto-restore session logic
- [ ] Create backend endpoint: `POST /api/auth/google` (needed for Phase 2)
- [ ] Implement JWT token management (deferred until backend integration)
- [ ] Add auto-refresh token logic (deferred until backend integration)

#### Navigation
- [x] Create app entry point with conditional auth gate
- [x] Create `HomeView` as main authenticated screen
- [ ] Set up tab navigation structure (deferred to Phase 2)
- [x] Add authentication gate (show SignInView if not logged in)

**Deliverable:** ✅ User can sign in with Google and see home screen with placeholder features

**Notes:**
- Chose to implement Google Sign-In first (Apple Sign-In deferred)
- Using Google SDK's built-in token management instead of custom JWT initially
- HomeView serves as landing page with quick action buttons
- Tab navigation will be added when multiple screens are implemented

---

### Phase 2: Core Data Layer (Week 2-3)
**Goal:** Swift Data models, local storage, HCPCS cache

#### Swift Data Models
- [ ] Create `Visit` model with @Model macro
- [ ] Create `Procedure` model with relationship
- [ ] Create `RVUCode` struct (Codable)
- [ ] Set up ModelContainer in app entry point
- [ ] Write model unit tests

#### HCPCS Cache
- [ ] Download `rvu_codes.json` from web app database
- [ ] Add JSON file to Xcode project (16,852 codes)
- [ ] Implement `RVUCacheService.loadCodes()`
- [ ] Implement search with fuzzy matching
- [ ] Add loading indicator on first launch
- [ ] Test search performance (should be <100ms)

#### Date Utilities
- [ ] Create `DateUtils.swift`
- [ ] Implement timezone-independent date handling
- [ ] Add ISO 8601 formatters
- [ ] Write date conversion unit tests

**Deliverable:** Local database ready, HCPCS codes searchable offline

---

### Phase 3: Quick Visit Entry (Week 3-4)
**Goal:** Primary mobile feature - fast procedure logging

#### Entry View
- [ ] Create `EntryView.swift` UI
- [ ] Add date/time pickers (default to now)
- [ ] Add notes text field (optional)
- [ ] Add no-show toggle
- [ ] Implement `EntryViewModel`

#### HCPCS Search
- [ ] Create `RVUSearchView.swift`
- [ ] Implement search bar with instant results
- [ ] Show HCPCS code, description, work RVU
- [ ] Add to procedures list on tap
- [ ] Support multiple procedures per visit

#### Procedure Management
- [ ] Display selected procedures list
- [ ] Add quantity stepper (default: 1)
- [ ] Calculate total RVU in real-time
- [ ] Swipe to delete procedure
- [ ] Validation: at least 1 procedure required

#### Save Logic
- [ ] Save visit to Swift Data
- [ ] Mark as "pending sync"
- [ ] Show success feedback
- [ ] Clear form for next entry
- [ ] Handle save errors gracefully

**Deliverable:** User can create visits offline with HCPCS search

---

### Phase 4: Visit History (Week 4-5)
**Goal:** View, edit, delete past visits

#### List View
- [ ] Create `VisitsListView.swift`
- [ ] Fetch visits from Swift Data (date DESC)
- [ ] Implement `VisitRowView` component
- [ ] Show date, total RVU, procedure count
- [ ] Add no-show badge (orange)
- [ ] Pull-to-refresh gesture

#### Visit Details
- [ ] Expandable procedure details
- [ ] Show all procedures with quantities
- [ ] Display notes if present
- [ ] Show created/updated timestamps

#### Edit & Delete
- [ ] Tap to edit visit
- [ ] Reuse `EntryView` with pre-filled data
- [ ] Update visit in Swift Data
- [ ] Swipe-to-delete with confirmation alert
- [ ] Cascade delete procedures
- [ ] Mark changes for sync

#### Copy Visit
- [ ] Add "Copy" action to visit row
- [ ] Pre-fill entry form with same procedures
- [ ] Update date to current

**Deliverable:** Full CRUD operations on visits

---

### Phase 5: API Integration (Week 5-6)
**Goal:** Connect to backend, implement sync

#### API Service
- [ ] Create `APIService.swift` actor
- [ ] Implement `fetchVisits()`
- [ ] Implement `createVisit(_:)`
- [ ] Implement `updateVisit(_:)`
- [ ] Implement `deleteVisit(id:)`
- [ ] Add JWT token to all requests
- [ ] Handle 401 (refresh token)
- [ ] Handle network errors

#### Sync Service
- [ ] Create `SyncService.swift`
- [ ] Implement upload pending changes
- [ ] Implement download server changes
- [ ] Merge local + server data
- [ ] Handle conflict resolution (server wins)
- [ ] Update sync status on models
- [ ] Add retry logic with exponential backoff

#### Network Monitoring
- [ ] Detect online/offline state
- [ ] Auto-sync when connection restored
- [ ] Show sync status indicator in UI
- [ ] Manual sync button (pull-to-refresh)

#### Background Sync
- [ ] Register background task
- [ ] Implement periodic sync (when app backgrounded)
- [ ] Test background sync reliability

**Deliverable:** Full offline-online synchronization working

---

### Phase 6: Favorites (Week 6)
**Goal:** Quick access to frequently used codes

#### Favorites Management
- [ ] Create `FavoritesView.swift`
- [ ] Fetch favorites from API
- [ ] Display in grid or list
- [ ] Tap to add procedure to visit
- [ ] Long press to reorder (drag and drop)

#### Add/Remove
- [ ] Star icon in HCPCS search results
- [ ] POST `/api/favorites` on add
- [ ] DELETE `/api/favorites/{hcpcs}` on remove
- [ ] Optimistic UI updates
- [ ] Sync favorites with server

**Deliverable:** Favorites working with drag-to-reorder

---

### Phase 7: Analytics Dashboard (Week 7-8)
**Goal:** RVU visualization and insights

#### Analytics View
- [ ] Create `AnalyticsView.swift`
- [ ] Add date range picker (7/30/90 days, custom)
- [ ] Implement `AnalyticsViewModel`
- [ ] Fetch data from local database
- [ ] Calculate summary metrics

#### Summary Cards
- [ ] Total RVUs (large number)
- [ ] Total Encounters
- [ ] Total No Shows
- [ ] Average RVU per Encounter

#### RVU Chart
- [ ] Create `ChartView.swift` with Swift Charts
- [ ] Line chart for RVU over time
- [ ] Support grouping: Daily, Weekly, Monthly, Yearly
- [ ] Interactive tooltips
- [ ] Smooth animations

#### HCPCS Breakdown
- [ ] Table grouped by date
- [ ] Show HCPCS code, description, RVU, count
- [ ] Collapsible sections by date
- [ ] Sort by RVU (descending)

#### Export
- [ ] Generate PDF from analytics
- [ ] Use PDFKit
- [ ] Share via iOS share sheet
- [ ] Include charts and tables

**Deliverable:** Complete analytics dashboard with export

---

### Phase 8: Polish & Testing (Week 8-9)
**Goal:** Production-ready quality

#### UI/UX Polish
- [ ] Consistent spacing and typography
- [ ] Smooth animations and transitions
- [ ] Loading states for all async operations
- [ ] Empty states with helpful messages
- [ ] Error messages user-friendly
- [ ] Haptic feedback on key actions
- [ ] Dark mode support
- [ ] Accessibility: VoiceOver, Dynamic Type

#### Performance
- [ ] Profile with Instruments
- [ ] Optimize list scrolling (lazy loading)
- [ ] Reduce memory footprint
- [ ] Test with 10K+ visits
- [ ] Optimize HCPCS search speed

#### Testing
- [ ] Unit tests for ViewModels (80%+ coverage)
- [ ] Unit tests for Services
- [ ] Unit tests for date utilities
- [ ] UI tests for critical flows:
  - Sign in
  - Create visit
  - Edit visit
  - Delete visit
  - Sync offline changes
- [ ] Manual testing: airplane mode scenarios
- [ ] Manual testing: poor network conditions
- [ ] Manual testing: sync conflicts

#### Bug Fixes
- [ ] Fix all known bugs
- [ ] Test edge cases (empty data, max values)
- [ ] Test on multiple devices (mini, Pro, Pro Max)
- [ ] Test on iOS 17.0 (minimum version)

**Deliverable:** Stable, polished app ready for TestFlight

---

### Phase 9: App Store Preparation (Week 9-10)
**Goal:** Submit to Apple App Store

#### App Store Assets
- [ ] App icon (1024x1024)
- [ ] Screenshots (6.7", 6.5", 5.5" iPhones)
- [ ] App preview video (optional but recommended)
- [ ] Marketing text and description
- [ ] Keywords for App Store SEO
- [ ] Privacy policy URL
- [ ] Support URL

#### App Store Connect
- [ ] Create app listing
- [ ] Fill in metadata
- [ ] Add app privacy details
- [ ] Set pricing (free)
- [ ] Select availability (countries)
- [ ] Add age rating (Medical - 4+)

#### Build Submission
- [ ] Archive build in Xcode
- [ ] Upload to App Store Connect
- [ ] Submit for review
- [ ] Respond to Apple feedback if needed

#### Launch
- [ ] Announce on website
- [ ] Update web app to show iOS download link
- [ ] Monitor crash reports
- [ ] Respond to user reviews

**Deliverable:** App live on App Store 🎉

---

## Data Models Specification

### Visit (Swift Data)
```swift
@Model
final class Visit {
    @Attribute(.unique) var id: UUID
    var userId: String
    var date: Date                    // Timezone-independent
    var time: Date?                   // Optional time component
    var notes: String?
    var isNoShow: Bool
    @Relationship(deleteRule: .cascade) var procedures: [Procedure]
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus        // .synced, .pendingSync, .conflict
    
    var totalRVU: Double {
        procedures.reduce(0) { $0 + ($1.workRVU * Double($1.quantity)) }
    }
}

enum SyncStatus: String, Codable {
    case synced
    case pendingSync
    case conflict
}
```

### Procedure (Swift Data)
```swift
@Model
final class Procedure {
    var id: UUID
    var hcpcs: String
    var description: String
    var statusCode: String
    var workRVU: Double
    var quantity: Int
    var visit: Visit?                  // Relationship to parent
}
```

### RVUCode (Cached)
```swift
struct RVUCode: Codable, Identifiable {
    let id: Int
    let hcpcs: String
    let description: String
    let statusCode: String
    let workRVU: Double
}
```

---

## API Endpoints Reference

### Authentication
```
POST /api/auth/apple
Body: { identityToken: string, user?: { email, name } }
Response: { token: string, user: User }

POST /api/auth/google
Body: { authorizationCode: string }
Response: { token: string, user: User }
```

### Visits
```
GET /api/visits
Response: Visit[]

POST /api/visits
Body: Visit
Response: Visit

PUT /api/visits/{id}
Body: Visit
Response: Visit

DELETE /api/visits/{id}
Response: 204 No Content
```

### Analytics
```
GET /api/analytics?period=last_30_days&groupBy=day
Response: { totalRVU, encounters, noShows, avgRVU, chartData }

GET /api/analytics?groupBy=hcpcs&start=2026-01-01&end=2026-01-31
Response: { breakdown: [{ date, hcpcs, description, rvu, count }] }
```

### Favorites
```
GET /api/favorites
Response: Favorite[]

POST /api/favorites
Body: { hcpcs: string, order?: number }
Response: Favorite

DELETE /api/favorites/{hcpcs}
Response: 204 No Content
```

---

## Testing Checklist

### Unit Tests
- [ ] VisitsViewModel CRUD operations
- [ ] EntryViewModel validation logic
- [ ] AnalyticsViewModel calculations
- [ ] APIService request formatting
- [ ] SyncService conflict resolution
- [ ] DateUtils timezone handling
- [ ] RVUCacheService search accuracy

### Integration Tests
- [ ] End-to-end visit creation and sync
- [ ] Offline mode → online sync flow
- [ ] Favorites sync with server
- [ ] Token refresh on 401

### UI Tests
- [ ] Sign in with Apple
- [ ] Create visit with multiple procedures
- [ ] Edit existing visit
- [ ] Delete visit with confirmation
- [ ] Search HCPCS codes
- [ ] Add/remove favorites
- [ ] View analytics charts
- [ ] Export PDF

### Manual Test Scenarios
- [ ] Create visit in airplane mode → go online → verify sync
- [ ] Edit same visit on web and iOS → resolve conflict
- [ ] Delete visit on web → sync on iOS → verify removed
- [ ] Poor network (Charles Proxy throttling)
- [ ] 10,000 visits performance test
- [ ] Different iPhone sizes (mini, standard, Pro Max)
- [ ] iOS 17.0 minimum version compatibility
- [ ] Dark mode appearance
- [ ] VoiceOver accessibility
- [ ] Dynamic Type (text size scaling)

---

## Success Metrics

### Performance Targets
- **App Launch:** < 2 seconds to main screen
- **HCPCS Search:** < 100ms for results
- **Visit Save:** < 200ms local save
- **Sync:** < 5 seconds for 100 visits
- **Memory:** < 150MB for typical usage

### Quality Targets
- **Crash-free Rate:** > 99.5%
- **Unit Test Coverage:** > 80%
- **App Store Rating:** > 4.5 stars
- **User Retention (30 day):** > 60%

---

## Risk Management

### Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Swift Data bugs | High | Fallback to CoreData if needed |
| Sync conflicts | Medium | Server-wins policy, clear UX |
| Large dataset performance | Medium | Pagination, lazy loading |
| Background sync unreliable | Low | Manual sync button, clear status |

### Business Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| App Store rejection | High | Follow guidelines, privacy policy |
| Low adoption | Medium | Feature parity with web, better UX |
| Backend API changes | Medium | Version API, graceful degradation |

---

## Notes & Decisions

### Architecture Decisions
1. **Why Swift Data?** Native, minimal code, iOS 17+ constraint acceptable
2. **Why no CoreData?** Swift Data is modern replacement, simpler syntax
3. **Why offline-first?** Medical professionals often in low-signal areas
4. **Why server-wins conflicts?** Simplicity, web app is primary platform
5. **Why @Observable instead of ObservableObject?** Modern Swift Observation framework (iOS 17+), better performance with fewer view updates

### Design Decisions
1. **iPhone only (v1):** Focus MVP, add iPad later
2. **Portrait only:** Medical workflows typically portrait
3. **No pagination:** Small dataset (< 10K visits typical), Swift Data handles well
4. **Bundled HCPCS:** Offline-first, codes rarely change

### Phase 1 Implementation Decisions (Jan 2026)
1. **Google Sign-In First:** Implemented Google before Apple Sign-In for faster MVP
   - Easier testing during development
   - Web app already uses Google
   - Apple Sign-In can be added in Phase 1.5
2. **UserDefaults for User Profile:** Non-sensitive public profile data (name, email, photo URL)
   - Google SDK stores secure tokens in Keychain automatically
   - Simplifies initial implementation
3. **Info.plist Location:** Placed at project root (not in synced folder) to avoid Xcode build conflicts
   - Xcode's PBXFileSystemSynchronizedRootGroup auto-includes files
   - Custom Info.plist must be outside synced directories
4. **HomeView as Landing:** Single home screen instead of tab navigation initially
   - Quick action buttons provide navigation to future features
   - Simpler for Phase 1, tabs can be added when multiple screens exist
5. **No Backend Integration Yet:** Using Google SDK token management temporarily
   - Backend JWT exchange will be added in Phase 2
   - Allows frontend development to proceed independently

### Future Enhancements
- iPad support with split-view
- Apple Watch complication
- Siri shortcuts ("Log my last procedure")
- Home screen widgets (RVU summary)
- Export to CSV/Excel
- Team collaboration features
- Custom RVU goals and alerts

---

## Contact & Resources

- **Backend API:** https://trackmyrvu.com/api
- **Web App:** https://trackmyrvu.com
- **Design System:** Follow iOS Human Interface Guidelines
- **Support:** [support email TBD]

---

**Document Status:** Living document - update as project evolves
**Last Review:** January 25, 2026 (Phase 1 Complete)
**Next Review:** After Phase 2 completion

---

## Phase 1 Build Configuration

### Verified Build Settings
- **Scheme:** trackmyrvu
- **Destination:** iOS Simulator (iPhone 17 Pro, iOS 26.2)
- **Configuration:** Debug
- **Build Status:** ✅ Clean build succeeds
- **GoogleSignIn SDK:** ✅ Resolved and linked (v9.1.0)

### Info.plist Configuration
```xml
Location: /Users/ddctu/git/track_my_rvu_ios/trackmyrvu/Info.plist

GIDClientID: 386826311054-ltu6cla9v0beb3k0p68o96ec5hfqv6ps.apps.googleusercontent.com
CFBundleURLSchemes: com.googleusercontent.apps.386826311054-ltu6cla9v0beb3k0p68o96ec5hfqv6ps
```

### Ready for Phase 2
With Phase 1 complete, the project is ready for:
1. **Swift Data Models** - Visit, Procedure models with relationships
2. **HCPCS Cache Service** - Load and search 16K codes offline
3. **Date Utilities** - Timezone-independent date handling
4. **Backend API Integration** - JWT token exchange with `/api/auth/google`

The authentication foundation is solid and all SwiftUI views follow modern patterns that can be extended for future features.