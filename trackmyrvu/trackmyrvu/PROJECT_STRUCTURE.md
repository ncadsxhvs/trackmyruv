# 📱 Track My RVU - Final Project Structure

## Overview
iOS app for tracking Relative Value Units (RVUs) with visit management, analytics, and favorites.

---

## 🏗️ Architecture

**Pattern:** MVVM (Model-View-ViewModel)
**Concurrency:** Swift Concurrency (async/await, @MainActor)
**State Management:** @Observable macro (iOS 17+)
**API:** RESTful backend at trackmyrvu.com

---

## 📁 Core Files (25 Total)

### 1. App Entry Point
```swift
trackmyrvuApp.swift
├── @main entry point
├── AuthViewModel state
└── Routes to HomeView or SignInView
```

### 2. Authentication (4 files)
```swift
AuthService.swift
├── Keychain token storage
├── Google Sign-In integration
└── Session management

AuthViewModel.swift
├── @Observable state
├── currentUser tracking
└── Sign in/out logic

SignInView.swift
└── Google Sign-In UI

User.swift
└── User model (Codable)
```

### 3. Home Screen (1 file)
```swift
HomeView.swift
├── Navigation hub
├── Profile header
├── Quick actions
├── Loads VisitsViewModel
└── Routes to other screens
```

### 4. Visits Management (5 files)
```swift
Visit.swift
├── Visit model
├── VisitProcedure model
└── totalWorkRVU computed property

VisitsViewModel.swift
├── @Observable @MainActor
├── Caches visits array
├── loadVisits() API call
└── deleteVisit() logic

VisitHistoryView.swift
├── List of all visits
├── Delete functionality
└── Detail navigation

NewVisitView.swift
├── Create visit form
├── Date/time selection
└── Procedure entry

EntryViewModel.swift
├── Form state management
├── RVU code search
└── Visit creation logic
```

### 5. Analytics (3 files)
```swift
AnalyticsView.swift
├── Total RVU card
├── Chart visualization
├── Period filters (daily/weekly/monthly/yearly)
└── Date range selection

AnalyticsViewModel.swift
├── @Observable @MainActor
├── Calculates from cached visits (NO API calls)
├── filterVisitsByDateRange()
├── calculateSummaries()
└── Instant computation

AnalyticsData.swift
├── AnalyticsPeriod enum
├── DateRangePreset enum
├── AnalyticsSummary model
└── SummaryStats helper
```

### 6. Favorites (4 files)
```swift
Favorite.swift
└── Favorite model (Codable)

FavoritesView.swift
├── List of favorite codes
├── Reorder with drag-drop
└── Add/remove functionality

FavoritesViewModel.swift
├── @Observable @MainActor
├── favorites array cache
├── CRUD operations
├── Reorder sync
└── UserDefaults caching

DebugFavoritesView.swift
└── Debug/testing view
```

### 7. RVU Search (2 files)
```swift
RVUSearchView.swift
├── Search HCPCS codes
├── RVU code details
└── Add to favorites

RVUCacheService.swift
├── Local RVU code cache
├── 2025 CMS data
└── Fast offline search
```

### 8. Utilities (2 files)
```swift
Date+Extensions.swift
├── dateString (ISO 8601)
├── formatted() helpers
├── startOfDay / endOfDay
└── isToday / isPast

APIService.swift
├── Actor-based API client
├── JWT Bearer auth
├── Snake_case decoding
├── Custom date decoder
└── Endpoints:
    ├── Visits CRUD
    ├── Favorites CRUD
    └── (Analytics removed - uses cached data)
```

---

## 🔄 Data Flow

### Visit History Flow
```
1. HomeView.onAppear
   ↓
2. VisitsViewModel.loadVisits()
   ↓
3. APIService.fetchVisits()
   ↓
4. Caches in VisitsViewModel.visits[]
   ↓
5. Available to all views
```

### Analytics Flow (Refactored)
```
1. User taps Analytics
   ↓
2. HomeView passes VisitsViewModel
   ↓
3. AnalyticsView → AnalyticsViewModel
   ↓
4. Filters cached visits by date range
   ↓
5. Groups by period (daily/weekly/etc)
   ↓
6. Calculates totals locally
   ↓
7. Displays instantly (no API call)
```

### Favorites Flow
```
1. User adds favorite
   ↓
2. FavoritesViewModel.addFavorite()
   ↓
3. APIService.createFavorite()
   ↓
4. Caches in favorites[] array
   ↓
5. Saves to UserDefaults
   ↓
6. Available offline
```

---

## 🎨 UI Components

### Navigation Structure
```
App Launch
├── SignInView (if not authenticated)
└── HomeView (if authenticated)
    ├── NavigationStack
    │   ├── visitHistory → VisitHistoryView
    │   ├── analytics → AnalyticsView
    │   └── debugFavorites → DebugFavoritesView
    └── Sheet
        └── newVisit → NewVisitView
```

### Reusable Components
- ProfileHeaderView
- RVUSummaryView
- QuickActionsView
- ActionButton
- StatCard (in AnalyticsView)

---

## 📊 Models

### Core Data Models
```swift
User: id, email, name, image
Visit: id, userId, date, time, notes, isNoShow, procedures[]
VisitProcedure: id, visitId, hcpcs, description, statusCode, workRVU, quantity
Favorite: id, userId, hcpcs, sortOrder
```

### Analytics Models (Local Only)
```swift
AnalyticsSummary: periodStart, totalWorkRvu, totalEncounters, totalNoShows
AnalyticsPeriod: daily, weekly, monthly, yearly
DateRangePreset: last7Days, last30Days, last90Days, thisMonth, etc.
```

---

## 🔧 Key Features

### ✅ Implemented
1. **Authentication** - Google Sign-In with JWT
2. **Visit Management** - Create, view, delete visits
3. **Analytics** - Calculate RVUs from cached data
4. **Favorites** - CRUD with offline caching
5. **RVU Search** - Offline HCPCS code lookup
6. **Offline Support** - UserDefaults caching

### 🎯 Technical Highlights
- **No API calls for analytics** - Instant calculations
- **Offline-first** - Caching with UserDefaults
- **Modern Swift** - Concurrency, @Observable, MVVM
- **Clean Code** - Separation of concerns
- **Error Handling** - Token expiration, network errors
- **Type Safety** - Codable, custom decoders

---

## 🚀 Build & Run

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Steps
```bash
1. Open trackmyrvu.xcodeproj
2. Select target device/simulator
3. Build: Cmd+B
4. Run: Cmd+R
```

### First Launch
1. Sign in with Google
2. App fetches visit history
3. Data cached locally
4. Navigate to Analytics
5. See instant RVU calculations

---

## 📝 File Count Summary

| Category | Files |
|----------|-------|
| App Entry | 1 |
| Authentication | 4 |
| Home | 1 |
| Visits | 5 |
| Analytics | 3 |
| Favorites | 4 |
| RVU Search | 2 |
| Utilities | 2 |
| Documentation | 3 |
| **TOTAL** | **25** |

---

## 🧪 Testing Checklist

- [ ] Build succeeds without errors
- [ ] App launches and shows sign-in
- [ ] Can sign in with Google
- [ ] Home screen loads
- [ ] Visit history displays
- [ ] Can create new visit
- [ ] Analytics shows total RVUs
- [ ] Filter changes are instant
- [ ] Favorites can be added/removed
- [ ] RVU search works offline
- [ ] App works offline after initial load

---

## 📚 Documentation Files

1. **CLEANUP_INSTRUCTIONS.md** - How to remove duplicates
2. **BUILD_FIX_INSTRUCTIONS.md** - Fixing build errors
3. **ANALYTICS_REFACTOR.md** - Analytics implementation details
4. **PROJECT_STRUCTURE.md** - This file

---

**Project is clean, organized, and ready for production!** 🎉
