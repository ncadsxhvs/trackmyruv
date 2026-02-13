### 1. Analytics Main Screen

**Controls (top):**
- Period picker: segmented control with Daily / Weekly / Monthly / Yearly
- Date range: two date pickers (start, end)
- Default: last 30 days, daily period
- When Yearly selected: auto-set Jan 1 - Dec 31 of current year

**View toggle:** Summary | HCPCS Breakdown (segmented control or tab bar)

### 2. Summary View

**Bar Chart:**
- X-axis: period labels (formatted dates)
- Y-axis: RVU values with 5 gridlines (0%, 25%, 50%, 75%, 100% of max)
- Bars: blue gradient, tappable to drill into breakdown for that period
- Line overlay: green trend line connecting bar tops with dot markers
- Horizontal scroll when >5 data points

**Stat Cards (4-column grid on iPad, 2x2 on iPhone):**

| Card | Color | Value | Subtitle |
|------|-------|-------|----------|
| Total RVUs | Blue | `sum(total_work_rvu)` | "Across all periods" |
| Total Encounters | Green | `sum(total_encounters)` | "Procedure records" |
| Total No Shows | Orange | `sum(total_no_shows)` | "Missed appointments" |
| Avg RVU/Encounter | Purple | `total_rvu / total_encounters` | "Efficiency metric" |

### 3. HCPCS Breakdown View

**Table grouped by period:**
- Section header per period: date label + procedure count
- Rows sorted by `total_work_rvu` DESC within each period
- Periods sorted DESC (newest first)

| Column | Alignment | Source |
|--------|-----------|--------|
| HCPCS | Left | `hcpcs` |
| Description | Left, truncated | `description` |
| Count | Right | `total_quantity` |
| Total RVU | Right, bold | `total_work_rvu` |
| Avg RVU | Right | `total_work_rvu / total_quantity` |

**Filtering:** Tapping a bar chart period shows only that period's breakdown. "Show All" clears the filter.
