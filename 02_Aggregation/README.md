#  Aggregation Deep Thinking

## Topics Covered
- COUNT(*) vs COUNT(col) vs COUNT(DISTINCT)
- NULL behavior in aggregation
- CASE WHEN inside aggregation
- HAVING vs WHERE (with execution order)
- Aggregation after JOINs
- MAX/MIN per group with ties
- Aggregate vs Window Functions
- SUM/AVG on conditional expressions
- DISTINCT inside aggregation
- Aggregation on derived columns
- ROLLUP & CUBE
- Duplicate handling
- GROUP BY deep practice

## Key Concepts Learned

### AVG Trap
AVG divides by COUNT(non-NULL) not COUNT(*)
Always use COALESCE when NULL should mean 0

### NULL Rules
- SUM/AVG/MIN/MAX → ignore NULLs
- COUNT(*) → counts NULLs
- COUNT(col) → ignores NULLs
- All-NULL group → returns NULL not 0

### CASE WHEN in Aggregation
- COUNT + CASE → no ELSE needed
- SUM + CASE → ELSE 0 needed
- AVG + CASE → never use ELSE 0!

### Safe Patterns
- NULLIF(denominator, 0) → safe division
- COALESCE(AGG(), 0) → NULL to zero
- COUNT(DISTINCT) → after JOIN always!

## Files
- `concepts.md` - Theory and explanations
- `group_by_practice.sql` - 6 complex problems
- `solutions.sql` - Solutions with comments
