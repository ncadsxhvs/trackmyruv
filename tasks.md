# RVU Tracker iOS - Remaining Tasks

## Completed
- [x] Google Sign-In authentication with backend JWT
- [x] Visit history (list, delete, caching)
- [x] Visit creation/editing with multi-procedure support
- [x] HCPCS code search from bundled CSV
- [x] Favorites (add, remove, reorder, cache)
- [x] Analytics dashboard (charts, stats, HCPCS breakdown)
- [x] RVU enrichment from local CSV
- [x] Codebase cleanup (removed dead code, debug prints, unused files)
- [x] Zero build warnings

## TODO

### High Priority (App Store Blockers)
- [ ] Apple Sign-In (required for App Store submission)
- [ ] App icon (1024x1024 + generated sizes)
- [ ] App Store screenshots (6.7", 6.5", 5.5")
- [ ] Privacy policy URL

### Medium Priority (Feature Completeness)
- [ ] Offline CRUD with Swift Data (currently reads from cache, writes need network)
- [ ] Sync service for offline changes
- [ ] Edit existing visits (currently can create, view, delete)
- [ ] Copy visit to create similar entry

### Low Priority (Polish)
- [ ] Pull-to-refresh on analytics
- [ ] Export analytics as PDF
- [ ] Background sync
- [ ] Network connectivity indicator
- [ ] Unit tests for ViewModels and Services
