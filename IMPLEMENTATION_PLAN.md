# RVU Tracker - Unified Implementation Plan
**Team Lead Coordination Document**
**Date:** February 8, 2026
**Status:** Ready for Implementation

---

## Executive Summary

This document coordinates the implementation of **Favorites** and **Analytics** features across backend (Next.js) and iOS platforms for the RVU Tracker application. Both teams will work in parallel on their respective implementations following this unified specification.

**Current Project Status:** ~60% Complete
- ✅ Authentication (Google OAuth with JWT)
- ✅ Visit CRUD operations (full stack)
- ✅ HCPCS code search (19,089 codes)
- 🔨 Favorites (backend API exists, iOS needs implementation)
- 🔨 Analytics (backend API exists, iOS needs implementation)

---

## Table of Contents

1. [API Alignment Review](#1-api-alignment-review)
2. [Favorites Feature Specification](#2-favorites-feature-specification)
3. [Analytics Feature Specification](#3-analytics-feature-specification)
4. [Data Format Standards](#4-data-format-standards)
5. [Implementation Roadmap](#5-implementation-roadmap)
6. [Testing & Integration](#6-testing--integration)
7. [Deployment Strategy](#7-deployment-strategy)

---

## 1. API Alignment Review

### 1.1 Backend Status

**Backend Repository:** `/Users/ddctu/git/hh/` (Next.js 16 + Postgres)

**Existing APIs (Production Ready):**
- ✅ `/api/visits` - Full CRUD (GET, POST, PUT, DELETE)
- ✅ `/api/favorites` - GET, POST, PATCH, DELETE
- ✅ `/api/analytics` - GET with period grouping and HCPCS breakdown
- ✅ `/api/rvu/search` - HCPCS code search

**Authentication:** Dual-mode
- Web: NextAuth session cookies
- Mobile: JWT Bearer tokens via `Authorization: Bearer <token>` header
- Helper: `getUserId(req)` in `/src/lib/mobile-auth.ts`

### 1.2 iOS Status

**iOS Repository:** `/Users/ddctu/git/track_my_rvu_ios/trackmyrvu/` (SwiftUI, iOS 17+)

**Existing Implementation:**
- ✅ Google Sign-In with JWT token storage (Keychain)
- ✅ APIService with Bearer token authentication
- ✅ Visit CRUD (fetch, create, update, delete)
- ✅ HCPCS search (local cache with 19,089 codes from bundled CSV)
- 🔨 Favorites (needs iOS implementation)
- 🔨 Analytics (needs iOS implementation)

### 1.3 Design Alignment

**✅ ALIGNED:**
- Authentication flow (JWT tokens)
- Visit data models (snake_case backend ↔ camelCase iOS)
- Error handling patterns (401, 404, 500 with JSON error messages)
- Date handling (YYYY-MM-DD strings, timezone-independent)

**⚠️ CLARIFICATIONS NEEDED:**
- None - Existing patterns are well-established and documented

**✅ NO GAPS IDENTIFIED:**
- Backend APIs match iOS requirements
- iOS can implement features with existing backend endpoints
- No missing endpoints

---

## 2. Favorites Feature Specification

### 2.1 Backend API (Already Implemented)

#### Database Schema
```sql
CREATE TABLE IF NOT EXISTS favorites (
  id SERIAL PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  hcpcs TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, hcpcs)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_user_sort ON favorites(user_id, sort_order);
```

#### API Endpoints

**1. GET /api/favorites**
- **Description:** Fetch user's favorite HCPCS codes
- **Auth:** Required (JWT Bearer token)
- **Query Params:** None
- **Response:** `200 OK`
```json
[
  {
    "id": 123,
    "user_id": "google-oauth2|123456",
    "hcpcs": "99213",
    "sort_order": 0,
    "created_at": "2026-02-08T10:00:00Z"
  },
  {
    "id": 456,
    "user_id": "google-oauth2|123456",
    "hcpcs": "99214",
    "sort_order": 1,
    "created_at": "2026-02-08T11:00:00Z"
  }
]
```

**2. POST /api/favorites**
- **Description:** Add a favorite
- **Auth:** Required
- **Body:**
```json
{
  "hcpcs": "99213"
}
```
- **Response:** `201 Created`
```json
{
  "id": 123,
  "user_id": "google-oauth2|123456",
  "hcpcs": "99213",
  "sort_order": 0,
  "created_at": "2026-02-08T10:00:00Z"
}
```

**3. PATCH /api/favorites (Reorder)**
- **Description:** Update sort order for drag-and-drop
- **Auth:** Required
- **Body:**
```json
{
  "favorites": [
    { "hcpcs": "99214", "sort_order": 0 },
    { "hcpcs": "99213", "sort_order": 1 },
    { "hcpcs": "99215", "sort_order": 2 }
  ]
}
```
- **Response:** `200 OK`
```json
{
  "success": true
}
```

**4. DELETE /api/favorites/[hcpcs]**
- **Description:** Remove a favorite
- **Auth:** Required
- **Path Param:** `hcpcs` (e.g., "99213")
- **Response:** `200 OK`
```json
{
  "message": "Favorite removed successfully"
}
```

### 2.2 iOS Implementation Tasks

**Phase 1: API Integration (2 days)**
- [ ] Create `Favorite` model in `Models/Favorite.swift`
  - Properties: `id`, `userId`, `hcpcs`, `sortOrder`, `createdAt`
  - Codable with snake_case ↔ camelCase conversion
- [ ] Add favorites methods to `Services/APIService.swift`:
  - `fetchFavorites() async throws -> [Favorite]`
  - `addFavorite(hcpcs: String) async throws -> Favorite`
  - `reorderFavorites(_ favorites: [Favorite]) async throws`
  - `removeFavorite(hcpcs: String) async throws`

**Phase 2: ViewModel & State (1 day)**
- [ ] Create `ViewModels/FavoritesViewModel.swift`
  - `@Published var favorites: [Favorite]`
  - `@Published var isLoading: Bool`
  - `@Published var error: String?`
  - Methods: `loadFavorites()`, `addFavorite()`, `removeFavorite()`, `reorderFavorites()`
  - Cache favorites in UserDefaults for offline access

**Phase 3: UI Components (3 days)**
- [ ] Create `Views/Favorites/FavoritesView.swift`
  - Grid layout (2 columns on iPhone)
  - Show: HCPCS code + description (from local RVU cache)
  - Tap to quick-add to visit
  - Swipe-to-delete action
  - Edit mode toggle for reordering
  - Empty state: "No favorites yet. Star codes from search to add them here."
- [ ] Add favorites section to `Views/Entry/NewVisitView.swift`
  - Display above search field
  - Show first 6 favorites with "See All" link
  - Tap favorite to add procedure to visit
- [ ] Update `Views/Entry/RVUSearchView.swift`
  - Add star icon (★/☆) next to each result
  - Filled star if already favorited
  - Tap star to toggle favorite
  - Sync with FavoritesViewModel

**Phase 4: Drag-and-Drop (2 days)**
- [ ] Implement drag-to-reorder in FavoritesView
  - SwiftUI native drag gesture (iOS 17+)
  - Visual feedback during drag
  - Optimistic UI update (reorder locally first)
  - Persist to backend via PATCH endpoint
  - Rollback on error
- [ ] Add haptic feedback on reorder complete

**Phase 5: Polish (1 day)**
- [ ] Loading states and error handling
- [ ] Offline support (cache in UserDefaults)
- [ ] Pull-to-refresh in FavoritesView
- [ ] Animations (add/remove favorites)
- [ ] Accessibility labels

**Total Estimate: 9 developer days**

### 2.3 User Flow

```
1. User searches for HCPCS code → sees star icon
2. Tap star → POST /api/favorites → code added to favorites
3. Navigate to Favorites tab → GET /api/favorites → list displayed
4. Drag to reorder → PATCH /api/favorites → order persisted
5. Swipe to delete → DELETE /api/favorites/[hcpcs] → favorite removed
6. From entry form → tap favorite → procedure added to visit
```

---

## 3. Analytics Feature Specification

### 3.1 Backend API (Already Implemented)

#### Endpoint: GET /api/analytics

**Query Parameters:**
- `period` - Grouping period: `daily`, `weekly`, `monthly`, `yearly` (default: `daily`)
- `start` - Start date in YYYY-MM-DD format (required)
- `end` - End date in YYYY-MM-DD format (required)
- `groupBy` - Optional: `hcpcs` for HCPCS breakdown (omit for summary view)

**Response Examples:**

**Summary View (no groupBy):**
```json
[
  {
    "period_start": "2026-02-01",
    "total_work_rvu": 12.5,
    "total_encounters": 8,
    "total_no_shows": 1
  },
  {
    "period_start": "2026-02-02",
    "total_work_rvu": 18.3,
    "total_encounters": 12,
    "total_no_shows": 0
  }
]
```

**HCPCS Breakdown (groupBy=hcpcs):**
```json
[
  {
    "period_start": "2026-02-01",
    "hcpcs": "99213",
    "description": "Office visit, 20-29 minutes",
    "status_code": "A",
    "total_work_rvu": 8.5,
    "total_quantity": 5,
    "encounter_count": 5
  },
  {
    "period_start": "2026-02-01",
    "hcpcs": "99214",
    "description": "Office visit, 30-39 minutes",
    "status_code": "A",
    "total_work_rvu": 4.0,
    "total_quantity": 2,
    "encounter_count": 2
  }
]
```

### 3.2 iOS Implementation Tasks

**Phase 1: API Integration (1 day)**
- [ ] Create analytics models in `Models/Analytics.swift`:
  - `AnalyticsSummary` (period_start, total_work_rvu, total_encounters, total_no_shows)
  - `AnalyticsHCPCS` (period_start, hcpcs, description, total_work_rvu, total_quantity, encounter_count)
  - Codable with snake_case conversion
- [ ] Add analytics methods to `Services/APIService.swift`:
  - `fetchAnalyticsSummary(startDate:endDate:period:) async throws -> [AnalyticsSummary]`
  - `fetchAnalyticsHCPCS(startDate:endDate:period:) async throws -> [AnalyticsHCPCS]`

**Phase 2: ViewModel & Logic (2 days)**
- [ ] Create `ViewModels/AnalyticsViewModel.swift`
  - `@Published var summaryData: [AnalyticsSummary]`
  - `@Published var hcpcsData: [AnalyticsHCPCS]`
  - `@Published var selectedPeriod: Period` (daily/weekly/monthly/yearly)
  - `@Published var dateRange: (start: Date, end: Date)`
  - Computed properties:
    - `totalRVU: Double` - Sum of all RVUs in date range
    - `totalEncounters: Int` - Sum of all encounters
    - `totalNoShows: Int` - Sum of no-shows
    - `avgRVUPerEncounter: Double` - totalRVU / totalEncounters
  - Methods: `loadData()`, `changePeriod()`, `changeDateRange()`

**Phase 3: UI - Summary Dashboard (3 days)**
- [ ] Create `Views/Analytics/AnalyticsView.swift`
  - Header: Date range picker + period segmented control
  - Summary metrics cards (2x2 grid):
    - Total RVUs (large font, blue icon)
    - Total Encounters (green icon)
    - Total No Shows (orange icon)
    - Avg RVU/Encounter (purple icon)
- [ ] Create `Views/Analytics/MetricCard.swift` component
  - Reusable card with icon, value, label
  - Skeleton loading state
  - Animation on value change

**Phase 4: Chart Visualization (3 days)**
- [ ] Import SwiftUI Charts framework
- [ ] Create `Views/Analytics/RVUChartView.swift`
  - Bar chart: X-axis (period_start), Y-axis (total_work_rvu)
  - Responsive to period changes (daily/weekly/monthly/yearly)
  - Custom colors matching app theme
  - Tap bar to show detail popover
  - Empty state: "No data for selected range"
  - Loading state: Skeleton bars
- [ ] Format X-axis labels based on period:
  - Daily: "Feb 1"
  - Weekly: "Week of Feb 1"
  - Monthly: "Feb 2026"
  - Yearly: "2026"

**Phase 5: HCPCS Breakdown Table (2 days)**
- [ ] Create `Views/Analytics/HCPCSBreakdownView.swift`
  - Grouped list by period (collapsible sections)
  - Each row shows:
    - HCPCS code
    - Description (truncated)
    - Count
    - Total RVU
  - Sort by total RVU descending
  - Search bar to filter by code or description
  - Empty state

**Phase 6: Date Range Picker (1 day)**
- [ ] Create `Views/Analytics/DateRangePickerView.swift`
  - Quick presets: Last 7 days, Last 30 days, Last 90 days, This Year
  - Custom date range with date pickers
  - Validation: start <= end
  - "Apply" button

**Phase 7: Export to PDF (Optional - 2 days)**
- [ ] Create `Utilities/PDFGenerator.swift`
- [ ] Render analytics view to PDF
- [ ] Add export button to toolbar
- [ ] Present share sheet (save or share PDF)

**Total Estimate: 12 developer days (14 with PDF export)**

### 3.3 User Flow

```
1. User navigates to Analytics tab
2. Default: Last 30 days, Daily grouping
3. GET /api/analytics?start=...&end=...&period=daily
4. Display summary cards + chart
5. User switches to "HCPCS Breakdown" tab
6. GET /api/analytics?start=...&end=...&period=daily&groupBy=hcpcs
7. Display grouped list of procedures
8. User changes period to "Weekly"
9. Refresh both endpoints with period=weekly
10. Charts and tables update
```

---

## 4. Data Format Standards

### 4.1 Case Conversion

**Backend (PostgreSQL & API):**
- Database columns: `snake_case` (e.g., `user_id`, `created_at`, `work_rvu`)
- JSON keys: `snake_case`

**iOS (Swift):**
- Properties: `camelCase` (e.g., `userId`, `createdAt`, `workRVU`)
- Use `JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase`
- Use `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase`

### 4.2 Date Formats

**API Transmission:**
- Dates: `YYYY-MM-DD` string (e.g., "2026-02-08")
- Times: `HH:MM:SS` string (e.g., "14:30:00")
- Timestamps: ISO 8601 (e.g., "2026-02-08T14:30:00Z")

**iOS Display:**
- Dates: Use `Date.FormatStyle` with local timezone
- Times: 12-hour format with AM/PM (e.g., "2:30 PM")
- Relative dates: "Today", "Yesterday", etc.

**Parsing:**
```swift
// iOS parsing (CRITICAL)
let dateFormatter = ISO8601DateFormatter()
dateFormatter.formatOptions = [.withFullDate]
let date = dateFormatter.date(from: "2026-02-08") // Timezone-independent
```

### 4.3 Numeric Formats

**RVU Values:**
- Type: `Double` (Swift), `NUMERIC` (PostgreSQL)
- Precision: 2 decimal places for display
- Format: "12.34" (no thousands separator)

**Quantities:**
- Type: `Int`
- Min: 1 (enforced in UI and API)

### 4.4 Error Response Format

**Standard Error Structure:**
```json
{
  "error": "Human-readable error message"
}
```

**HTTP Status Codes:**
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (missing/invalid token)
- `404` - Not Found
- `500` - Internal Server Error

**iOS Error Handling:**
```swift
enum APIError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String?)
    case decoding(Error)
    case notAuthenticated
    case tokenExpired

    var errorDescription: String? {
        // User-friendly messages
    }
}
```

---

## 5. Implementation Roadmap

### 5.1 Phase Breakdown

**Phase 1: Favorites Feature (2 weeks)**
- Week 1: iOS implementation (API integration, ViewModel, basic UI)
- Week 2: iOS polish (drag-and-drop, animations, offline support)
- Backend: No work needed (API already exists)

**Phase 2: Analytics Feature (3 weeks)**
- Week 1: iOS implementation (API integration, ViewModel, summary dashboard)
- Week 2: iOS implementation (chart visualization, HCPCS breakdown)
- Week 3: iOS polish (date picker, export to PDF, testing)
- Backend: No work needed (API already exists)

**Phase 3: Testing & Integration (1 week)**
- Unit tests (iOS ViewModels, APIService)
- Integration tests (E2E flows)
- Performance testing (large datasets)
- Bug fixes

**Phase 4: Deployment (1 week)**
- TestFlight beta release
- QA testing
- App Store submission preparation

**Total Timeline: 7 weeks**

### 5.2 Parallel Work Streams

**iOS Team (Primary Focus):**
1. Favorites implementation (Weeks 1-2)
2. Analytics implementation (Weeks 3-5)
3. Testing and polish (Week 6)
4. Deployment (Week 7)

**Backend Team (Support Role):**
- No new features needed (APIs already exist)
- Bug fixes if iOS discovers issues
- Performance optimization if needed
- Database indexing review

### 5.3 Dependencies

**Critical Path:**
- iOS Favorites → iOS Analytics → Testing → Deployment
- No blocking dependencies between features

**Parallel Work:**
- Favorites and Analytics can be developed in parallel by separate iOS developers
- Backend team can focus on other projects (Todo API, etc.)

---

## 6. Testing & Integration

### 6.1 Backend Testing

**Existing Coverage:**
- ✅ 57 passing tests (Jest)
- ✅ Favorites API tested
- ✅ Analytics API tested
- ✅ Date handling tests (23 tests)

**Additional Tests (If Needed):**
- [ ] Favorites reordering edge cases
- [ ] Analytics with large datasets (10K+ visits)
- [ ] Analytics with no-show visits

### 6.2 iOS Testing

**Unit Tests:**
- [ ] FavoritesViewModel tests
  - Add/remove favorites
  - Reorder favorites
  - Error handling
- [ ] AnalyticsViewModel tests
  - Calculate metrics correctly
  - Handle empty data
  - Period grouping logic
- [ ] APIService tests
  - Mock network responses
  - Error handling
  - Token expiration

**UI Tests:**
- [ ] Favorites flow (add → reorder → delete)
- [ ] Analytics flow (change period → change date range)
- [ ] Offline behavior (cached favorites)

**Integration Tests:**
- [ ] End-to-end favorites flow with real backend
- [ ] End-to-end analytics flow with real backend
- [ ] Token refresh on expiration

### 6.3 Testing Strategy

**Test Environments:**
- Development: `http://localhost:3001/api`
- Staging: `https://staging.trackmyrvu.com/api` (if available)
- Production: `https://www.trackmyrvu.com/api`

**Test Data:**
- Create test user with Google OAuth
- Seed test visits with known RVU values
- Verify analytics calculations match expected results

**Performance Testing:**
- Test with 1000+ visits
- Test with 50+ favorites
- Measure API response times
- Test offline mode responsiveness

---

## 7. Deployment Strategy

### 7.1 Backend Deployment

**Status:** Backend is already deployed to production
- ✅ Favorites API live at `https://www.trackmyrvu.com/api/favorites`
- ✅ Analytics API live at `https://www.trackmyrvu.com/api/analytics`
- ✅ Database schema includes all required tables

**No backend deployment needed for this release.**

### 7.2 iOS Deployment

**Pre-Deployment Checklist:**
- [ ] All features implemented and tested
- [ ] Unit tests passing (70%+ coverage)
- [ ] UI tests passing
- [ ] Performance acceptable (smooth 60 FPS)
- [ ] Accessibility labels added
- [ ] App icons and launch screen created
- [ ] Privacy policy updated (if needed)

**TestFlight Beta:**
1. Build archive in Xcode
2. Upload to App Store Connect
3. Submit for TestFlight review
4. Invite internal testers (5-10 users)
5. Collect feedback (1 week)
6. Fix critical bugs

**App Store Submission:**
1. Create App Store listing
   - Screenshots (6.7", 6.5", 5.5")
   - Description and keywords
   - Privacy policy URL
2. Submit for review
3. Respond to feedback (1-3 days)
4. Release approved build

**Estimated Timeline:**
- TestFlight beta: Week 7
- App Store submission: Week 8
- App Store approval: Week 9
- Public release: Week 9

### 7.3 Rollback Plan

**If Critical Bug Found:**
1. Pause App Store release
2. Roll back to previous beta build
3. Fix bug in hotfix branch
4. Re-test and re-submit

**Backend Rollback:**
- Not needed (backend is stable and tested)
- If API bug found, backend team can deploy fix independently

---

## 8. Success Metrics

### 8.1 Feature Completion

**Favorites:**
- ✅ User can add/remove favorites
- ✅ User can reorder favorites
- ✅ Favorites persist to backend
- ✅ Quick-add from favorites to visit
- ✅ Offline support (cached favorites)

**Analytics:**
- ✅ Summary metrics displayed (RVUs, encounters, no-shows, avg)
- ✅ Chart visualization (bar chart with period grouping)
- ✅ HCPCS breakdown table
- ✅ Date range picker (presets + custom)
- ✅ Export to PDF (optional)

### 8.2 Performance Targets

- API response time: < 500ms (p95)
- App launch time: < 2 seconds
- Smooth scrolling: 60 FPS
- Offline favorites access: Instant

### 8.3 Quality Metrics

- Unit test coverage: > 70%
- Crash-free rate: > 99.5%
- App Store rating: > 4.5 stars (target)

---

## 9. Communication & Coordination

### 9.1 Daily Standups

**Format:** 15-minute daily sync
- What did you complete yesterday?
- What are you working on today?
- Any blockers?

**Participants:** iOS developer(s), backend developer (as needed), team lead

### 9.2 Weekly Progress Reviews

**Format:** 30-minute weekly review
- Demo completed features
- Review metrics (velocity, test coverage)
- Adjust timeline if needed

### 9.3 Async Communication

**Tools:**
- GitHub Issues for bug tracking
- Pull Requests for code review
- Slack/Discord for quick questions

**Best Practices:**
- Tag team lead for urgent blockers
- Document decisions in GitHub comments
- Update this plan as needed

---

## 10. Risk Mitigation

### 10.1 Identified Risks

**Risk 1: Backend API Issues**
- **Probability:** Low (APIs already tested)
- **Impact:** High (blocks iOS development)
- **Mitigation:** Test APIs thoroughly before iOS work starts

**Risk 2: iOS Drag-and-Drop Complexity**
- **Probability:** Medium (new feature for team)
- **Impact:** Medium (delays favorites feature)
- **Mitigation:** Spike task to validate approach, use SwiftUI native APIs

**Risk 3: Analytics Chart Performance**
- **Probability:** Low (Swift Charts is optimized)
- **Impact:** Medium (poor UX)
- **Mitigation:** Test with large datasets early, implement pagination if needed

**Risk 4: App Store Rejection**
- **Probability:** Low (straightforward app)
- **Impact:** High (delays release)
- **Mitigation:** Follow Apple guidelines strictly, include privacy policy

### 10.2 Contingency Plans

**If Favorites Takes Longer:**
- Ship Analytics first (independent feature)
- Release Favorites in subsequent update

**If Analytics Chart is Too Complex:**
- Use simple table view instead of chart
- Add chart in future update

**If Timeline Slips:**
- Cut scope (e.g., PDF export)
- Extend timeline by 1-2 weeks

---

## 11. Next Steps

### 11.1 Immediate Actions (This Week)

**iOS Team:**
1. Review this implementation plan
2. Ask clarifying questions
3. Set up project board with tasks from this document
4. Begin Favorites Phase 1 (API integration)

**Backend Team:**
5. Verify favorites API is working correctly
6. Verify analytics API handles all edge cases
7. Review performance with large datasets

**Team Lead:**
8. Schedule daily standup meetings
9. Create GitHub project board
10. Assign tasks to developers

### 11.2 Long-Term Goals

**Post-MVP Features:**
- Offline support with Swift Data
- Apple Sign-In (alternative to Google)
- Visit templates (save common procedure combinations)
- Push notifications (reminders, sync status)
- iPad support (multi-column layout)

---

## Appendix A: API Quick Reference

### Favorites

```bash
# Fetch favorites
GET /api/favorites
Authorization: Bearer <JWT>

# Add favorite
POST /api/favorites
Authorization: Bearer <JWT>
Body: {"hcpcs": "99213"}

# Reorder favorites
PATCH /api/favorites
Authorization: Bearer <JWT>
Body: {"favorites": [{"hcpcs": "99213", "sort_order": 0}, ...]}

# Remove favorite
DELETE /api/favorites/99213
Authorization: Bearer <JWT>
```

### Analytics

```bash
# Summary view (daily)
GET /api/analytics?start=2026-02-01&end=2026-02-28&period=daily
Authorization: Bearer <JWT>

# HCPCS breakdown (monthly)
GET /api/analytics?start=2026-01-01&end=2026-12-31&period=monthly&groupBy=hcpcs
Authorization: Bearer <JWT>
```

---

## Appendix B: File Structure Reference

### Backend (Next.js)

```
/Users/ddctu/git/hh/
├── src/app/api/
│   ├── favorites/
│   │   ├── route.ts (GET, POST, PATCH)
│   │   └── [hcpcs]/route.ts (DELETE)
│   ├── analytics/
│   │   └── route.ts (GET)
│   ├── visits/
│   │   ├── route.ts (GET, POST)
│   │   └── [id]/route.ts (PUT, DELETE)
│   └── auth/mobile/google/
│       └── route.ts (POST)
├── src/lib/
│   ├── db.ts (Postgres client)
│   ├── mobile-auth.ts (JWT helpers)
│   └── dateUtils.ts (Timezone-safe dates)
└── scripts/
    ├── init-db.sql
    └── add-favorites-sort-order.sql
```

### iOS (SwiftUI)

```
/Users/ddctu/git/track_my_rvu_ios/trackmyrvu/trackmyrvu/
├── Models/
│   ├── User.swift
│   ├── Visit.swift
│   ├── Favorite.swift (TO CREATE)
│   └── Analytics.swift (TO CREATE)
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── VisitsViewModel.swift
│   ├── EntryViewModel.swift
│   ├── FavoritesViewModel.swift (TO CREATE)
│   └── AnalyticsViewModel.swift (TO CREATE)
├── Views/
│   ├── Auth/
│   │   └── SignInView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Visits/
│   │   └── VisitHistoryView.swift
│   ├── Entry/
│   │   ├── NewVisitView.swift
│   │   └── RVUSearchView.swift
│   ├── Favorites/ (TO CREATE)
│   │   └── FavoritesView.swift
│   └── Analytics/ (TO CREATE)
│       ├── AnalyticsView.swift
│       ├── MetricCard.swift
│       ├── RVUChartView.swift
│       ├── HCPCSBreakdownView.swift
│       └── DateRangePickerView.swift
├── Services/
│   ├── APIService.swift (add favorites + analytics methods)
│   ├── AuthService.swift
│   └── RVUCacheService.swift
└── trackmyrvuApp.swift
```

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-08 | Team Lead | Initial implementation plan |

---

**End of Implementation Plan**

This document is the single source of truth for Favorites and Analytics implementation. Both teams should refer to this document throughout the development process. Any changes to scope, timeline, or specifications should be documented in revisions to this plan.
