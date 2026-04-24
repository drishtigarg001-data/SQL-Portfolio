# Window Functions

## Topics Covered
- ROW_NUMBER vs RANK vs DENSE_RANK
- PARTITION BY vs GROUP BY
- Top N per group
- Running totals
- Moving averages
- LAG / LEAD
- Finding gaps & islands
- De-duplication using window functions
- Aggregate vs Window functions

## Key Concepts
- Window functions retain all rows — no collapsing!
- PARTITION BY = group wise calculation
- No PARTITION BY = overall calculation
- ORDER BY inside OVER() = running calculation
- GROUP BY collapses rows, OVER() does not

## PARTITION BY Rules
- Group wise ranking → PARTITION BY column
- Overall ranking → No PARTITION BY
- Running total per group → PARTITION BY group column
- Running total overall → No PARTITION BY

## ROW_NUMBER vs RANK vs DENSE_RANK
- ROW_NUMBER → always unique, no ties handled
- RANK → ties get same rank, next rank skipped
- DENSE_RANK → ties get same rank, no gap ✅

## When to Use Window vs Aggregate
- Need row + group data together → Window Function
- Need only summary → GROUP BY
- Rankings needed → Window Function
- Running totals → Window Function
- LAG/LEAD comparison → Window Function

## Files
- `concepts.sql` - Theory and key patterns
- `practice.sql` - Questions + Answers + Corrections
