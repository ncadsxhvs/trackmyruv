# RVU Tracker iOS - Tasks

**Project:** RVU Tracker iOS Application
**Version:** 1.0.0 MVP
**Status:** In Progress (~60% Complete)
**Last Updated:** February 8, 2026

---

## Current Status

### ✅ Completed Features

**Authentication**
- Google Sign-In with dual OAuth client configuration (iOS + Server)
- JWT token storage in Keychain
- Token validation and expiration handling
- Backend integration with `/api/auth/mobile/google`
- Auto-sign-in on app launch
- Sign-out functionality

**Visit Management (Full CRUD)**
- View all visits from backend (`GET /api/visits`)
- Create new visits with multiple procedures (`POST /api/visits`)
- Edit existing visits (`PUT /api/visits/{id}`)
- Delete visits with confirmation (`DELETE /api/visits/{id}`)
- Date and optional time selection
- Multiple procedures per visit with quantities
- No-show visit support
- Notes field
- Real-time total RVU calculation
- Visit history list with pull-to-refresh
- Swipe-to-delete with confirmation dialog
- Swipe-to-edit navigation
- Modal form for new/edit visit entry
- Optimistic UI updates on delete

**API Integration**
- APIService with JWT authentication
- Fetch visits endpoint (`GET /api/visits`)
- Create visit endpoint (`POST /api/visits`)
- Update visit endpoint (`PUT /api/visits/{id}`)
- Delete visit endpoint (`DELETE /api/visits/{id}`)
- Error handling (401, 500, network errors)
- Snake_case ↔ CamelCase conversion

**HCPCS Code Search**
- RVUCacheService loads 19,089 codes from bundled CSV
- In-memory search with fuzzy matching
- Search by HCPCS code or description
- Autocomplete with 300ms debounce
- Results sorted by relevance (exact match > prefix > alphabetical)
- Limit to 100 results for performance
- RVUSearchView with clean search UI
- Empty state, loading state, no results state

**Models & ViewModels**
- User model (Codable, matches backend)
- Visit model with flexible decoding (String/Int IDs)
- VisitProcedure model
- CreateVisitRequest and CreateProcedureRequest
- AuthViewModel (@Observable, iOS 17+)
- VisitsViewModel for list management
- EntryViewModel for form management

**UI Components**
- SignInView with Google authentication
- HomeView with navigation and profile
- VisitHistoryView with swipe actions (edit/delete), loading/error/empty states
- NewVisitView with complete form (date, time, procedures, notes, no-show)
- RVUSearchView with autocomplete search
- Profile header with AsyncImage

---

## Pending Features

### 🔨 Visits (Improvements)

**Completed** ✅
- Edit existing visit (update date, time, procedures, quantities, notes)
- Delete visit with confirmation dialog
- Update APIService: `updateVisit(_:)` method (PUT `/api/visits/{id}`)
- Update APIService: `deleteVisit(id:)` method (DELETE `/api/visits/{id}`)
- Add swipe-to-delete action in VisitHistoryView
- Add edit navigation from visit row
- Update EntryViewModel to support edit mode
- Optimistic UI updates

**Pending Improvements**
- [ ] No-show quick-add button (bypasses procedure requirement)
- [ ] Copy visit feature (duplicate procedures to new visit)
- [ ] Show sync status indicator per visit (local vs synced)

---

### ⭐ Favorites

**Backend API** (requires backend implementation)
- [ ] `GET /api/favorites` - Fetch user's favorite HCPCS codes
- [ ] `POST /api/favorites` - Add favorite (body: `{hcpcs, sort_order}`)
- [ ] `DELETE /api/favorites/{hcpcs}` - Remove favorite
- [ ] `PUT /api/favorites/reorder` - Update sort order (body: `[{hcpcs, sort_order}]`)

**iOS Implementation**
- [ ] Add favorites methods to APIService
- [ ] Create FavoritesViewModel with state management
- [ ] Create FavoritesView with grid/list layout
- [ ] Display in EntryView as section above search
- [ ] Tap favorite to quick-add to visit
- [ ] Show star icon in search results (filled if favorited)
- [ ] Toggle favorite from search results
- [ ] Cache favorites locally (UserDefaults or Swift Data)
- [ ] Sync with server on app launch and when online

**Drag-and-Drop Reordering**
- [ ] Implement drag-to-reorder in FavoritesView
- [ ] Update sort_order locally on drag
- [ ] Persist order to server via `/api/favorites/reorder`
- [ ] Show edit mode toggle
- [ ] Optimistic UI updates

**UI/UX**
- [ ] Empty state: "No favorites yet"
- [ ] Visual feedback on add/remove (haptic + animation)
- [ ] Swipe-to-delete from favorites list

---

### 📊 Analytics

**Backend API** (requires backend implementation)
- [ ] `GET /api/analytics?startDate=...&endDate=...&groupBy=...`
  - Query params: `startDate` (YYYY-MM-DD), `endDate` (YYYY-MM-DD), `groupBy` (day|week|month|year)
  - Returns: Chart data points, summary metrics
- [ ] `GET /api/analytics/hcpcs?startDate=...&endDate=...`
  - Returns: Per-HCPCS breakdown with counts and RVU totals

**iOS Implementation**
- [ ] Add analytics methods to APIService
- [ ] Create AnalyticsViewModel with state management
- [ ] Create AnalyticsView with dashboard layout
- [ ] Date range picker (Last 7/30/90 days, Custom)
- [ ] Grouping picker (Daily, Weekly, Monthly, Yearly)
- [ ] Calculate metrics from fetched data

**Summary Metrics Cards**
- [ ] Total RVUs (large, prominent)
- [ ] Total Encounters
- [ ] Total No Shows
- [ ] Avg RVU per Encounter
- [ ] Style as 2x2 grid with icons

**Chart Visualization**
- [ ] Import SwiftUI Charts framework
- [ ] Create bar chart: X-axis (date), Y-axis (RVU)
- [ ] Animate on data change
- [ ] Responsive to grouping changes
- [ ] Handle empty data state

**HCPCS Breakdown Table**
- [ ] Display as grouped list (by date or by code)
- [ ] Show: HCPCS, description, count, total RVU
- [ ] Sort by total RVU descending
- [ ] Make sections collapsible
- [ ] Add search/filter by code or description

**Export to PDF**
- [ ] Create PDFGenerator utility
- [ ] Render summary metrics to PDF
- [ ] Render chart as image
- [ ] Render HCPCS breakdown table
- [ ] Add toolbar export button
- [ ] Present iOS share sheet (save or share)

---

## Infrastructure & Polish

### Offline Support (Future)
- [ ] Swift Data models (Visit, Procedure)
- [ ] ModelContainer setup
- [ ] Local-first architecture
- [ ] Sync service (upload pending, download changes)
- [ ] Conflict resolution (server wins)
- [ ] Network monitoring (NWPathMonitor)
- [ ] Auto-sync on app launch and network reconnection
- [ ] Sync status indicator UI

### Apple Sign-In (Optional)
- [ ] Enable Apple Sign-In capability in Xcode
- [ ] Backend: `POST /api/auth/apple` endpoint
- [ ] Implement Apple Sign-In flow in AuthService
- [ ] Add "Sign in with Apple" button to SignInView

### Testing & QA
- [ ] Unit tests for ViewModels
- [ ] Unit tests for APIService
- [ ] Unit tests for date utilities
- [ ] UI tests for critical flows (sign in, create visit, sync)
- [ ] Test offline mode (airplane mode)
- [ ] Test sync conflicts
- [ ] Test error states and edge cases

### App Store Preparation
- [ ] Create app icons (1024x1024 + all sizes)
- [ ] Create launch screen
- [ ] Add privacy policy URL
- [ ] Add App Store description and keywords
- [ ] Create screenshots (6.7", 6.5", 5.5")
- [ ] TestFlight beta testing
- [ ] Submit to App Store review

---

## Development Notes

**Architecture**
- SwiftUI with MVVM pattern
- @Observable macro for view models (iOS 17+)
- Actor-based APIService for thread safety
- JWT Bearer token authentication via Keychain

**Code Conventions**
- API uses snake_case (backend), iOS uses camelCase
- All dates as ISO 8601 strings (YYYY-MM-DD) for API
- Display dates in local timezone
- Force unwrap only when guaranteed safe
- Prefer async/await over completion handlers

**API Configuration**
- Base URL: `https://www.trackmyrvu.com/api`
- OAuth Client IDs:
  - iOS: `386826311054-ltu6cla9v0beb3k0p68o96ec5hfqv6ps.apps.googleusercontent.com`
  - Server: `386826311054-hic8jh474jh1aiq6dclp2oor9mgc981l.apps.googleusercontent.com`

**Known Issues**
- None currently

---

**Next Priority Tasks:**
1. ✅ ~~Implement edit/delete visit functionality~~ (COMPLETED)
2. ✅ ~~Bundle and integrate HCPCS code search~~ (COMPLETED)
3. Build favorites feature (requires backend API)
4. Build analytics dashboard (requires backend API)
5. Add visit improvements (no-show quick-add, copy feature)
6. Add offline support with Swift Data
7. Polish UI/UX and test thoroughly
