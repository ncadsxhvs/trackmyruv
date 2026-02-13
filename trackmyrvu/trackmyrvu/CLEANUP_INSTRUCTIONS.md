# 🧹 Codebase Cleanup Instructions

## Files to DELETE from Xcode

### Duplicate Analytics Files (Created by Mistake)
1. **AnalyticsView 3.swift** - DELETE
2. **AnalyticsView 5.swift** - DELETE
3. **AnalyticsView 6.swift** - DELETE
4. **AnalyticsView 9.swift** - DELETE
5. **AnalyticsViewModel 2.swift** - DELETE

### Unused Sample Code
6. **ContentView.swift** - DELETE (Google Sign-In sample, not used in app)

### Optional (Task Documentation)
7. **task.md** - OPTIONAL: Delete after feature completion

---

## How to Delete Files in Xcode

### Method 1: Project Navigator
1. Open Xcode
2. Show Project Navigator (Cmd+1)
3. Select file to delete
4. Right-click → **Delete**
5. Choose "**Move to Trash**"
6. Repeat for all files above

### Method 2: Multiple Selection
1. Hold **Cmd** key
2. Click each file to select multiple
3. Right-click → **Delete**
4. Choose "**Move to Trash**"

---

## After Cleanup - Verify Project Structure

Your project should have this clean structure:

```
trackmyrvu/
├── App Entry
│   └── trackmyrvuApp.swift
│
├── Home
│   └── HomeView.swift
│
├── Authentication
│   ├── AuthService.swift
│   ├── AuthViewModel.swift
│   ├── SignInView.swift
│   └── User.swift
│
├── Visits
│   ├── Visit.swift
│   ├── VisitsViewModel.swift
│   ├── VisitHistoryView.swift
│   ├── NewVisitView.swift
│   └── EntryViewModel.swift
│
├── Analytics
│   ├── AnalyticsView.swift          ← Keep (no number)
│   ├── AnalyticsViewModel.swift     ← Keep (no number)
│   └── AnalyticsData.swift
│
├── Favorites
│   ├── Favorite.swift
│   ├── FavoritesView.swift
│   ├── FavoritesViewModel.swift
│   └── DebugFavoritesView.swift
│
├── RVU Search
│   ├── RVUSearchView.swift
│   └── RVUCacheService.swift
│
└── Utilities
    ├── Date+Extensions.swift
    └── APIService.swift
```

---

## Clean Build After Deletion

1. **Clean Build Folder**
   ```
   Product → Clean Build Folder (Cmd+Shift+K)
   ```

2. **Delete Derived Data** (if needed)
   ```
   Xcode → Preferences → Locations → Derived Data
   Click arrow → Delete folder
   ```

3. **Rebuild Project**
   ```
   Product → Build (Cmd+B)
   ```

---

## Expected Result

✅ **No build errors**
✅ **No ambiguous type warnings**
✅ **Clean project navigator**
✅ **All features working**

---

## File Count

**Before Cleanup:** ~32 files (with duplicates)
**After Cleanup:** ~25 files (clean)

**Removed:** 7 duplicate/unnecessary files

---

## If You Encounter Issues

### Issue: "File not found"
- File might already be deleted
- Skip and continue

### Issue: "Cannot delete"
- File might be open in editor
- Close all tabs, then try again

### Issue: Build errors after cleanup
- Clean build folder
- Restart Xcode
- Check that correct files remain (no numbers in names)

---

## Verification Checklist

After cleanup, verify:

- [ ] Project builds successfully (Cmd+B)
- [ ] App runs without crashes (Cmd+R)
- [ ] Home screen loads
- [ ] Can navigate to Visit History
- [ ] Can navigate to Analytics
- [ ] Analytics shows cached data
- [ ] No duplicate file errors in console

---

**Ready to clean up! Follow the steps above to remove duplicate files.** 🧹
