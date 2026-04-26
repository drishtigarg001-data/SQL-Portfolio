-- =============================================
-- AGGREGATION DEEP THINKING — CONCEPTS
-- =============================================

-- =============================================
-- 1. COUNT VARIATIONS
-- =============================================

-- THEORY:
-- COUNT(*)          → counts ALL rows including NULLs
-- COUNT(col)        → counts only NON-NULL values
-- COUNT(DISTINCT col)→ counts unique NON-NULL values

-- EXAMPLE:
SELECT
  COUNT(*)                    AS total_rows,
  COUNT(amount)               AS non_null_amount,
  COUNT(DISTINCT customer_id) AS unique_customers
FROM orders;

-- KEY TRAP:
-- COUNT(COALESCE(col, 0)) = COUNT(*)
-- COALESCE converts NULL to 0
-- 0 is NOT NULL → COUNT counts everything!
-- Never use COALESCE inside COUNT!

-- =============================================
-- 2. NULL BEHAVIOR IN AGGREGATION
-- =============================================

-- THEORY:
-- SUM   → ignores NULLs (does NOT treat as 0!)
-- AVG   → ignores NULLs in BOTH numerator & denominator
-- MIN   → ignores NULLs
-- MAX   → ignores NULLs
-- COUNT(col) → ignores NULLs
-- COUNT(*)   → counts NULLs!

-- IMPORTANT: NULL means UNKNOWN not ZERO!
-- MIN(500, 300, NULL) = 300 NOT 0!

-- THE AVG TRAP:
-- AVG(col) = SUM(non-NULL) / COUNT(non-NULL)
-- NOT = SUM(col) / COUNT(*)

-- Example:
-- amounts: 500, 300, NULL
-- AVG = (500+300) / 2 = 400  ✅
-- NOT = (500+300) / 3 = 267  ❌

-- NULL SAFE PATTERNS:
-- Treat NULL as 0 in AVG:
SELECT AVG(COALESCE(amount, 0)) FROM orders;

-- Treat NULL as 0 in SUM:
SELECT SUM(COALESCE(amount, 0)) FROM orders;

-- Handle NULL result from aggregation:
SELECT COALESCE(SUM(amount), 0) AS total FROM orders;

-- Safe division:
SELECT completed / NULLIF(total, 0) AS rate FROM summary;

-- ALL NULL group → returns NULL not 0!
-- Always wrap: COALESCE(AGG(col), 0)

-- =============================================
-- 3. HAVING vs WHERE
-- =============================================

-- THEORY:
-- SQL Execution Order:
-- FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY

-- WHERE  → filters ROWS before grouping
--          cannot use aggregate functions!
-- HAVING → filters GROUPS after aggregation
--          can use aggregate functions!

-- EXAMPLE:
SELECT dept, SUM(salary) AS total
FROM employees
WHERE region = 'North'      -- row filter BEFORE grouping
GROUP BY dept
HAVING SUM(salary) > 100000; -- group filter AFTER aggregation

-- COMMON MISTAKE:
-- WHERE SUM(salary) > 100000  ← ERROR!
-- SUM not calculated yet at WHERE stage!

-- WHERE + HAVING together:
SELECT dept, SUM(salary) AS total
FROM employees
WHERE join_year >= 2020           -- filter rows first
GROUP BY dept
HAVING SUM(salary) > 50000;      -- then filter groups

-- =============================================
-- 4. CASE WHEN IN AGGREGATION
-- =============================================

-- THEORY:
-- COUNT + CASE → NO ELSE needed!
--   → NULL = skip (COUNT ignores NULLs)
-- SUM + CASE   → ELSE 0 needed!
--   → NULL would propagate otherwise
-- AVG + CASE   → NO ELSE 0! NEVER!
--   → ELSE 0 dilutes average incorrectly!

-- Conditional COUNT:
SELECT
  COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed,
  COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled
FROM orders;

-- Conditional SUM:
SELECT
  SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) AS completed_rev,
  SUM(CASE WHEN status = 'cancelled' THEN amount ELSE 0 END) AS cancelled_rev
FROM orders;

-- Conditional AVG — NO ELSE 0!
SELECT
  AVG(CASE WHEN category = 'Electronics' THEN amount END) AS avg_electronics
  -- ELSE NULL by default → AVG ignores NULLs ✅
FROM orders;

-- Bucketization:
SELECT
  CASE
    WHEN salary < 50000 THEN 'Low'
    WHEN salary < 75000 THEN 'Mid'
    WHEN salary >= 75000 THEN 'High'
    ELSE 'Unknown'
  END AS salary_bucket,
  COUNT(*) AS emp_count
FROM employees
GROUP BY
  CASE
    WHEN salary < 50000 THEN 'Low'
    WHEN salary < 75000 THEN 'Mid'
    WHEN salary >= 75000 THEN 'High'
    ELSE 'Unknown'
  END;

-- =============================================
-- 5. AGGREGATION AFTER JOINS
-- =============================================

-- GOLDEN RULE:
-- Multiple one-to-many tables → pre-aggregate first!
-- Raw JOIN → duplicate explosion → wrong SUM!

-- WRONG:
SELECT c.name,
  SUM(o.amount) AS orders,    -- inflated!
  SUM(p.amount) AS payments   -- inflated!
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN payments p ON c.customer_id = p.customer_id
GROUP BY c.name;

-- CORRECT:
WITH order_totals AS (
  SELECT customer_id, SUM(amount) AS total_orders
  FROM orders GROUP BY customer_id
),
payment_totals AS (
  SELECT customer_id, SUM(amount) AS total_payments
  FROM payments GROUP BY customer_id
)
SELECT c.name, ot.total_orders, pt.total_payments
FROM customers c
LEFT JOIN order_totals ot ON c.customer_id = ot.customer_id
LEFT JOIN payment_totals pt ON c.customer_id = pt.customer_id;

-- COUNT(DISTINCT) after JOIN:
SELECT c.city,
  COUNT(DISTINCT c.customer_id) AS customers, -- not COUNT(*)!
  COUNT(o.order_id) AS orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city;

-- =============================================
-- 6. MAX/MIN PER GROUP WITH TIES
-- =============================================

-- WRONG: Cannot mix name with MAX in GROUP BY dept
SELECT dept, name, MAX(salary)
FROM employees
GROUP BY dept;
-- ERROR in PostgreSQL/BigQuery!
-- MySQL → random name returned!

-- CORRECT: CTE approach
WITH dept_max AS (
  SELECT dept, MAX(salary) AS max_sal
  FROM employees
  GROUP BY dept
)
SELECT e.dept, e.name, e.salary
FROM employees e
JOIN dept_max d
  ON e.dept = d.dept
  AND e.salary = d.max_sal;
-- Returns ALL employees with max salary
-- Ties handled correctly! ✅

-- =============================================
-- 7. AGGREGATE vs WINDOW FUNCTIONS
-- =============================================

-- GROUP BY → collapses rows into groups
-- Window   → retains all rows

-- GROUP BY:
SELECT dept, SUM(salary) AS dept_total
FROM employees
GROUP BY dept;
-- Only dept + total visible!

-- Window Function:
SELECT
  dept,
  name,
  salary,
  SUM(salary) OVER(PARTITION BY dept) AS dept_total
FROM employees;
-- All rows visible with dept total! ✅

-- CANNOT mix regular aggregate with window:
-- SELECT SUM(salary), SUM(salary) OVER(...) ← ERROR!
-- Use CTE or subquery to separate them!

-- =============================================
-- 8. DISTINCT IN AGGREGATION
-- =============================================

-- COUNT(DISTINCT) → safe and common ✅
SELECT COUNT(DISTINCT customer_id) FROM orders;

-- SUM(DISTINCT) → DANGEROUS! Almost always wrong!
SELECT SUM(DISTINCT amount) FROM orders;
-- Only adds unique amounts → loses real transactions!

-- AVG(DISTINCT) → Same danger as SUM(DISTINCT)!

-- Multi-column DISTINCT → MySQL only!
SELECT COUNT(DISTINCT customer_id, product_id) FROM orders;
-- PostgreSQL/BigQuery workaround:
SELECT COUNT(DISTINCT CONCAT(customer_id,'-',product_id))
FROM orders;

-- =============================================
-- 9. ROLLUP & CUBE
-- =============================================

-- ROLLUP → hierarchical subtotals
SELECT region, category, SUM(amount)
FROM sales
GROUP BY ROLLUP(region, category);
-- Returns: individual + region subtotals + grand total

-- CUBE → all possible combination subtotals
SELECT region, category, SUM(amount)
FROM sales
GROUP BY CUBE(region, category);
-- Returns: individual + region subtotals
--        + category subtotals + grand total

-- GROUPING() → distinguish NULL subtotal vs actual NULL
SELECT
  CASE GROUPING(region)
    WHEN 1 THEN 'ALL REGIONS'
    ELSE region
  END AS region,
  SUM(amount) AS total
FROM sales
GROUP BY ROLLUP(region);

-- ROLLUP vs CUBE on single column → SAME result!
-- Difference shows with 2+ columns!

-- =============================================
-- 10. DUPLICATE HANDLING
-- =============================================

-- Find exact duplicates:
SELECT customer_id, amount, status,
  COUNT(*) AS duplicate_count
FROM orders
GROUP BY customer_id, amount, status
HAVING COUNT(*) > 1;

-- Keep latest record (ROW_NUMBER):
WITH ranked AS (
  SELECT *,
    ROW_NUMBER() OVER(
      PARTITION BY customer_id  -- group by business key
      ORDER BY created_at DESC  -- latest first
    ) AS rn
  FROM orders
)
SELECT * FROM ranked WHERE rn = 1;

-- Find departments with tied max salary (RANK):
WITH dept_max AS (
  SELECT dept, MAX(salary) AS max_sal
  FROM employees GROUP BY dept
),
ranked AS (
  SELECT e.dept, e.name,
    RANK() OVER(
      PARTITION BY e.dept
      ORDER BY e.salary DESC
    ) AS rnk,
    COUNT(*) OVER(PARTITION BY e.dept) AS tie_count
  FROM employees e
  JOIN dept_max d ON e.dept = d.dept
    AND e.salary = d.max_sal
)
SELECT * FROM ranked WHERE tie_count > 1;

-- Delete duplicates keep lowest id:
DELETE FROM orders
WHERE order_id NOT IN (
  SELECT MIN(order_id)
  FROM orders
  GROUP BY customer_id, amount, status
);

-- Pipeline deduplication (MERGE):
MERGE INTO final_table f
USING staging s
ON f.customer_id = s.customer_id
  AND f.created_at = s.created_at
WHEN NOT MATCHED THEN
  INSERT VALUES(s.order_id, s.customer_id,
                s.amount, s.created_at);

-- =============================================
-- KEY RULES TO REMEMBER
-- =============================================

-- RULE 1: AVG trap
-- AVG = SUM(non-NULL) / COUNT(non-NULL)
-- NOT = SUM / COUNT(*)!

-- RULE 2: NULL vs 0
-- NULL = unknown/missing
-- Aggregates IGNORE NULLs, not treat as 0!
-- Use COALESCE when 0 behavior needed!

-- RULE 3: CASE WHEN
-- COUNT + CASE → no ELSE (NULL = skip)
-- SUM + CASE   → ELSE 0 needed
-- AVG + CASE   → no ELSE 0 (dilutes average!)

-- RULE 4: Safe patterns
-- NULLIF(denominator, 0) → safe division
-- COALESCE(AGG(), 0)     → NULL result to 0
-- COUNT(DISTINCT)        → after JOIN always!

-- RULE 5: Pre-aggregation
-- Multiple one-to-many → pre-aggregate!
-- Raw JOIN → duplicate explosion!

-- RULE 6: ROLLUP vs CUBE
-- ROLLUP → hierarchical subtotals
-- CUBE   → all possible subtotals
-- Single column → same result!
