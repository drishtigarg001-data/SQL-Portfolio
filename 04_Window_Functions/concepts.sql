-- =============================================
-- WINDOW FUNCTIONS — COMPLETE CONCEPTS
-- =============================================

-- =============================================
-- 1. GROUP BY vs WINDOW FUNCTIONS
-- =============================================

-- THEORY:
-- GROUP BY → collapses rows into groups
--            loses individual row detail
--            only group summary visible

-- Window Functions → retains ALL rows
--                    adds group calculation alongside
--                    row count stays same!

-- GROUP BY example:
SELECT dept, SUM(salary) AS dept_total
FROM employees
GROUP BY dept;
-- Result: 3 rows (one per dept)
-- Individual employees NOT visible!

-- Window Function example:
SELECT dept, name, salary,
  SUM(salary) OVER(PARTITION BY dept) AS dept_total
FROM employees;
-- Result: 10 rows (all employees)
-- dept_total added to EACH row! ✅

-- CANNOT mix aggregate + window in same level!
-- ❌ Wrong:
-- SELECT dept, name, SUM(salary), SUM(salary) OVER(...)
-- FROM employees GROUP BY dept;

-- ✅ Fix: Use CTE to separate them
WITH dept_summary AS (
  SELECT dept, SUM(salary) AS dept_total
  FROM employees GROUP BY dept
)
SELECT e.name, e.salary,
  SUM(e.salary) OVER(PARTITION BY e.dept) AS window_total
FROM employees e
JOIN dept_summary d ON e.dept = d.dept;

-- =============================================
-- 2. PARTITION BY vs GROUP BY
-- =============================================

-- PARTITION BY:
-- → Divides data into windows (like GROUP BY)
-- → But RETAINS all rows!
-- → Used inside OVER() clause

-- GROUP BY:
-- → Collapses rows into groups
-- → Loses individual rows!
-- → Used standalone

-- PARTITION BY rules:
-- PARTITION BY alone → static group total
SUM(amount) OVER(PARTITION BY region)
-- Every row in North → 59000 (complete North total)

-- PARTITION BY + ORDER BY → running total per group
SUM(amount) OVER(PARTITION BY region ORDER BY sale_date)
-- North row 1 → 15000
-- North row 2 → 35000 (resets at South boundary!)

-- No PARTITION BY + ORDER BY → running total overall
SUM(amount) OVER(ORDER BY sale_date)
-- No reset! Overall running total!

-- No PARTITION BY, No ORDER BY → grand total
SUM(amount) OVER()
-- Every row → same grand total!

-- Multiple PARTITION BY columns:
SUM(amount) OVER(PARTITION BY rep_id, region)
-- Groups by BOTH rep AND region!

-- =============================================
-- 3. ROW_NUMBER vs RANK vs DENSE_RANK
-- =============================================

-- Given salaries: 80000, 80000, 60000, 55000

-- ROW_NUMBER():
-- → Always unique numbers
-- → No ties handled
-- → 1, 2, 3, 4 (arbitrary for ties)
ROW_NUMBER() OVER(PARTITION BY dept ORDER BY salary DESC)
-- Alice 80000 → 1
-- Bob   80000 → 2  ← different from Alice!
-- Charlie 60000 → 3
-- Julia 55000 → 4

-- RANK():
-- → Ties get same rank
-- → Gap after ties!
-- → 1, 1, 3, 4 (rank 2 missing!)
RANK() OVER(PARTITION BY dept ORDER BY salary DESC)
-- Alice 80000 → 1
-- Bob   80000 → 1  ← same rank!
-- Charlie 60000 → 3  ← gap! rank 2 missing!
-- Julia 55000 → 4

-- DENSE_RANK():
-- → Ties get same rank
-- → NO gap after ties! ✅
-- → 1, 1, 2, 3 (sequential!)
DENSE_RANK() OVER(PARTITION BY dept ORDER BY salary DESC)
-- Alice 80000 → 1
-- Bob   80000 → 1  ← same rank!
-- Charlie 60000 → 2  ← no gap! ✅
-- Julia 55000 → 3

-- WHEN TO USE:
-- ROW_NUMBER → Deduplication (exactly 1 row!)
--              Pagination (unique row numbers!)
-- RANK       → Competition style (gaps acceptable)
--              Rarely used in practice!
-- DENSE_RANK → Nth highest salary ✅
--              Top N with ties ✅
--              Sequential ranking!

-- =============================================
-- 4. EXECUTION ORDER + WHY NOT IN WHERE
-- =============================================

-- SQL Execution Order:
-- FROM → JOIN → WHERE → GROUP BY →
-- HAVING → SELECT → DISTINCT → ORDER BY → LIMIT

-- Window functions run in SELECT phase (Step 6)
-- WHERE runs in Step 3 → BEFORE SELECT!

-- ❌ This FAILS:
-- SELECT customer_id, amount,
--   ROW_NUMBER() OVER(PARTITION BY customer_id
--                     ORDER BY amount DESC) AS rn
-- FROM orders
-- WHERE rn = 1;  -- ERROR! rn not calculated yet!

-- ✅ Fix 1: Subquery
SELECT customer_id, amount
FROM (
  SELECT customer_id, amount,
    ROW_NUMBER() OVER(
      PARTITION BY customer_id
      ORDER BY amount DESC
    ) AS rn
  FROM orders
) ranked
WHERE rn = 1;

-- ✅ Fix 2: CTE (preferred!)
WITH ranked AS (
  SELECT customer_id, amount,
    ROW_NUMBER() OVER(
      PARTITION BY customer_id
      ORDER BY amount DESC
    ) AS rn
  FROM orders
)
SELECT customer_id, amount
FROM ranked
WHERE rn = 1;

-- HAVING also fails for same reason!
-- HAVING runs Step 5 → BEFORE SELECT Step 6!

-- ORDER BY works! ✅
-- ORDER BY runs Step 8 → AFTER SELECT Step 6!
SELECT name, salary,
  RANK() OVER(ORDER BY salary DESC) AS rnk
FROM employees
ORDER BY rnk;  -- ✅ works!

-- Memory trick for execution order:
-- "From Join Where Group Having Select Distinct Order Limit"
-- F  J  W  G  H  S  D  O  L

-- =============================================
-- 5. NTILE()
-- =============================================

-- THEORY:
-- → Divides rows into N equal buckets
-- → Returns bucket number (1, 2, 3...N)
-- → Ordered by ORDER BY column
-- → If not evenly divisible → earlier buckets get extra row!

-- Example: 10 rows → NTILE(4)
-- 10/4 = 2 remainder 2
-- Bucket 1: 3 rows ← gets extra!
-- Bucket 2: 3 rows ← gets extra!
-- Bucket 3: 2 rows
-- Bucket 4: 2 rows

-- NTILE(3) with 10 rows:
-- 10/3 = 3 remainder 1
-- Bucket 1: 4 rows ← gets extra!
-- Bucket 2: 3 rows
-- Bucket 3: 3 rows

-- Performance buckets example:
WITH bucketed AS (
  SELECT rep_id, amount,
    NTILE(4) OVER(ORDER BY amount DESC) AS bucket
  FROM sales
)
SELECT
  rep_id, amount, bucket,
  CASE
    WHEN bucket = 1 THEN 'Excellent'
    WHEN bucket = 2 THEN 'Good'
    WHEN bucket = 3 THEN 'Average'
    ELSE 'Needs Improvement'
  END AS performance_label
FROM bucketed;

-- NTILE vs DENSE_RANK:
-- NTILE → divides into equal groups (percentile!)
--         "Top 25% customers"
-- DENSE_RANK → ranks each row individually
--              "2nd highest salary"

-- =============================================
-- 6. TOP N PER GROUP
-- =============================================

-- THEORY:
-- Most common window function use case!
-- Use DENSE_RANK for ties included!
-- Use ROW_NUMBER for exactly N rows!

-- Top 2 earners per dept (ties included):
WITH ranked AS (
  SELECT name, dept, salary,
    DENSE_RANK() OVER(
      PARTITION BY dept
      ORDER BY salary DESC
    ) AS rnk
  FROM employees
)
SELECT name, dept, salary, rnk
FROM ranked
WHERE rnk <= 2;
-- DENSE_RANK → no gaps → all tied rows included!

-- Exactly 1 employee per dept (with tiebreaker):
WITH ranked AS (
  SELECT name, dept, rating, hire_date,
    ROW_NUMBER() OVER(
      PARTITION BY dept
      ORDER BY rating DESC, hire_date ASC
    ) AS rn
  FROM employees
)
SELECT name, dept, rating
FROM ranked
WHERE rn = 1;
-- ROW_NUMBER → unique → exactly 1 row per dept!
-- Tiebreaker: if same rating → earliest hire_date wins!

-- WRONG approach — does NOT give top N per group!
-- SELECT * FROM employees ORDER BY salary DESC LIMIT 2;
-- This gives top 2 from ENTIRE table, not per dept!

-- DECISION RULE:
-- "Ties included" → DENSE_RANK ✅
-- "Exactly N rows" → ROW_NUMBER ✅
-- "Competition style" → RANK (rarely used)

-- =============================================
-- KEY RULES TO REMEMBER
-- =============================================

-- RULE 1: GROUP BY collapses, Window retains!
-- RULE 2: PARTITION BY = GROUP BY but rows kept!
-- RULE 3: PARTITION BY + ORDER BY = running total (resets per partition!)
-- RULE 4: No PARTITION BY + ORDER BY = overall running total!
-- RULE 5: No PARTITION BY, No ORDER BY = grand total!
-- RULE 6: ROW_NUMBER → unique, no ties
-- RULE 7: RANK → ties same rank, gap after!
-- RULE 8: DENSE_RANK → ties same rank, NO gap! ✅
-- RULE 9: Window functions in WHERE → ERROR!
--         Always wrap in subquery or CTE!
-- RULE 10: NTILE → equal buckets, earlier gets extra if uneven!
-- RULE 11: Top N with ties → DENSE_RANK!
-- RULE 12: Deduplication → ROW_NUMBER!
-- RULE 13: Pagination → ROW_NUMBER!
-- RULE 14: Nth highest salary → DENSE_RANK!
-- RULE 15: Cannot mix GROUP BY + Window in same level!
--          Use CTE to separate them!
