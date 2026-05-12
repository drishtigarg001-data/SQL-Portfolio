# 🪟 Window Functions

## Topics Covered

### 🔴 Must Have
| # | Topic | Status |
|---|-------|--------|
| 1 | GROUP BY vs Window Functions | ✅ Complete |
| 2 | PARTITION BY vs GROUP BY | ✅ Complete |
| 3 | ROW_NUMBER() | ✅ Complete |
| 4 | RANK() | ✅ Complete |
| 5 | DENSE_RANK() | ✅ Complete |
| 6 | NTILE() | ✅ Complete |
| 7 | Execution Order | ✅ Complete |
| 8 | Why Window not in WHERE | ✅ Complete |
| 9 | Top-N per group | ✅ Complete |
| 10 | Deduplication using window | ✅ Complete |
| 11 | First/Last per group | ✅ Complete |
| 12 | LAG() | ✅ Complete |
| 13 | LEAD() | ✅ Complete |
| 14 | FIRST_VALUE() | ✅ Complete |
| 15 | LAST_VALUE() + Trap | ✅ Complete |
| 16 | Running Total | ✅ Complete |
| 17 | Moving Average | ✅ Complete |
| 18 | Gaps & Islands | ⏳ Pending |

### 🟡 Important
| # | Topic | Status |
|---|-------|--------|
| 19 | Window Frames (ROWS vs RANGE) | ⏳ Pending |
| 20 | Change Detection | ⏳ Pending |
| 21 | Sessionization | ⏳ Pending |
| 22 | Window vs Subquery vs CTE | ⏳ Pending |
| 23 | NTH_VALUE() | ⏳ Pending |
| 24 | PERCENT_RANK / CUME_DIST | ⏳ Pending |

## Key Concepts
- Window functions RETAIN all rows — no collapsing!
- PARTITION BY = group wise calculation
- No PARTITION BY = overall/grand total calculation
- ORDER BY inside OVER() = running/cumulative calculation
- PARTITION BY + ORDER BY = running total per group (resets!)
- GROUP BY collapses rows → Window functions do NOT!
- Cannot use window functions in WHERE clause!
- Window functions run in SELECT phase → after WHERE/GROUP BY

## ROW_NUMBER vs RANK vs DENSE_RANK
- ROW_NUMBER → always unique, no ties handled
- RANK → ties get same rank, next rank SKIPPED (gap!)
- DENSE_RANK → ties get same rank, NO gap ✅
- Use DENSE_RANK for Nth highest salary!

## PARTITION BY Rules
- PARTITION BY alone → static group total (like GROUP BY but rows retained)
- PARTITION BY + ORDER BY → running total per group (resets at boundary!)
- No PARTITION BY + ORDER BY → running total across ALL rows (no reset!)
- No PARTITION BY, No ORDER BY → grand total same for every row
- Multiple columns → PARTITION BY col1, col2

## When to Use Window vs Aggregate
- Need row + group data together → Window Function ✅
- Need only summary → GROUP BY ✅
- Rankings needed → Window Function ✅
- Running totals → Window Function ✅
- LAG/LEAD comparison → Window Function ✅
- ETL deduplication → ROW_NUMBER() ✅

## Moving Average:
- ROWS BETWEEN N PRECEDING AND CURRENT ROW
- Fixed window slides forward!
- Different from running total!

## ROWS vs RANGE:
- ROWS = physical rows (accurate!)
-  RANGE = same value grouped (default, can surprise!)
-  For accurate results → always use ROWS!

## Gaps & Islands:
- Generate series → LEFT JOIN → find NULLs
-  ROW_NUMBER trick for islands!

## Change Detection:
- LAG + compare with current
-  WHERE current != prev OR prev IS NULL

## Sessionization:
- LAG for time gap
- CASE WHEN gap > threshold → new session flag
- Cumulative SUM of flags = session ID!

## Window vs Subquery vs CTE:
- Window → best for row + group together
- CTE → complex multi-step
-  Subquery → simple one-time

## NTH_VALUE:
- Like LAST_VALUE → needs frame fix
- Returns value at position N

## PERCENT_RANK + CUME_DIST:
- Both return 0 to 1
- PERCENT_RANK → position based (first = 0)
- CUME_DIST → distribution based (first > 0)
- Use in CTE → filter in outer query!


## Files
- `concepts.sql` - Theory and key patterns
- `practice.sql` - Questions + Datasets + Hints
- `solutions.sql` - Solutions + Key points
- `important_notes.sql` - Interview traps + Senior sentences
