# 🔍 Subqueries & CTEs

## Topics Covered
- Scalar Subqueries
- Correlated Subqueries
- Subquery in WHERE / FROM / SELECT
- EXISTS vs IN vs NOT EXISTS vs NOT IN
- CTE vs Subquery vs Derived Table
- Classic Problems (2nd highest, Nth highest, Dept avg)
- Multiple CTEs Chaining
- Subquery vs JOIN Performance
- Recursive CTE
- CTE Materialization vs Inlining
- CTE vs Temp Table vs View
- Performance Implications

## Key Concepts
- Subquery in WHERE/SELECT → single column only!
- Subquery in FROM → multiple columns okay, alias required!
- EXISTS → NULL safe, short circuits on first match
- NOT IN → NULL trap! Use NOT EXISTS instead
- Correlated → runs N times (once per row)
- Non-Correlated → runs once
- PARTITION BY → group wise ranking only
- No PARTITION BY → overall ranking

## When to Use What
- Row vs Scalar → Non-Correlated Subquery
- Row vs Row → Correlated Subquery
- Row vs Group → Correlated Subquery
- Group vs Scalar → HAVING + Scalar Subquery
- Group vs Group → CTE + WHERE
- All three together → Complex business problems

## Files
- `concepts.sql` - Theory and key patterns
- `practice.sql` - Questions + Answers + Corrections
