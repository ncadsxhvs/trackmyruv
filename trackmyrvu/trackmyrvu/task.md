Feature: Analytics Page – Total RVU

Goal:
When the "Analytics" button is tapped, navigate to a new screen that displays the total RVU calculated from all visit history.

Requirements:

1. Navigation
- On Analytics button tap → push/present AnalyticsView.

2. Data
- Fetch visit history from existing API.
- Each record contains: rvu (Double).
- Compute:
    totalRVU = sum(all rvu)

Prefer:
- If backend supports it, call:
    GET /analytics/total-rvu
    Response: { total_rvu: Double }

3. UI
- Title: "Total RVU"
- Display formatted value (2 decimal places).
- Handle loading + error + empty state (show 0).

Constraints:
- Minimal code.
- No duplicate logic.
- Follow existing architecture (MVVM if present).
- Keep business logic out of the View.
