-- =============================================
-- SUBQUERIES & CTEs — IMPORTANT NOTES
-- =============================================
-- Key concepts, traps, and decision rules
-- that are commonly asked in interviews!
-- =============================================

-- =============================================
-- NOTE 1: WHEN TO USE WHAT
-- (Scalar vs Correlated vs CTE)
-- =============================================

-- DECISION TABLE:
-- ┌─────────────────┬──────────────────────────┐
-- │ Comparison Type │ Use                      │
-- ├─────────────────┼──────────────────────────┤
-- │ Row vs Scalar   │ Non-Correlated Subquery  │
-- │ Row vs Row      │ Correlated Subquery      │
-- │ Row vs Group    │ Correlated Subquery      │
-- │ Group vs Scalar │ HAVING + Scalar Subquery │
-- │ Group vs Group  │ CTE + WHERE              │
-- └─────────────────┴──────────────────────────┘

-- Row vs Scalar (fixed company average):
WHERE salary > (SELECT AVG(salary) FROM employees)
-- → Runs ONCE, returns single value

-- Row vs Row (manager comparison):
WHERE salary > (
  SELECT salary FROM employees
  WHERE emp_id = e1.manager_id
)
-- → Correlated, runs N times

-- Row vs Group (dept average per row):
WHERE salary > (
  SELECT AVG(salary) FROM employees
  WHERE dept = e1.dept
)
-- → Correlated, different result per row

-- Group vs Scalar (dept total vs company avg):
HAVING SUM(salary) > (SELECT AVG(salary) FROM employees)
-- → HAVING + scalar subquery

-- Group vs Group (dept avg vs avg of dept avgs):
WITH dept_totals AS (
  SELECT dept, SUM(salary) AS total
  FROM employees GROUP BY dept
)
SELECT dept, total FROM dept_totals
WHERE total > (SELECT AVG(total) FROM dept_totals);
-- → CTE + WHERE

-- =============================================
-- NOTE 2: ALL THREE TOGETHER
-- (Scalar + Correlated + CTE)
-- =============================================

-- Real world scenario:
-- "Find employees earning more than both
--  dept average AND company average"

WITH dept_avg AS (
  -- CTE → Group level pre-calculation
  SELECT dept, AVG(salary) AS dept_average
  FROM employees
  GROUP BY dept
)
SELECT
  e.name,
  e.dept,
  e.salary,
  -- Scalar Subquery → Row vs Scalar
  (SELECT AVG(salary) FROM employees) AS company_avg,
  -- CTE value → Row vs Group
  da.dept_average
FROM employees e
JOIN dept_avg da ON e.dept = da.dept
WHERE
  -- Correlated → Row vs Group comparison
  e.salary > (
    SELECT AVG(salary) FROM employees e2
    WHERE e2.dept = e.dept
  )
  AND
  -- Scalar → Row vs Scalar comparison
  e.salary > (SELECT AVG(salary) FROM employees);

-- KEY INSIGHT:
-- Correlated subquery can be replaced by CTE!
-- CTE approach → more readable + performant!
-- Use all three when:
-- → Multiple levels of comparison needed
-- → Row + Group + Global data together required

-- =============================================
-- NOTE 3: CTE vs SUBQUERY PERFORMANCE
-- =============================================

-- MYTH: "Subquery is always slower than CTE"
-- REALITY: Depends on use case!

-- PostgreSQL 12+ behavior:
-- → CTE automatically inlined (not materialized)
-- → Optimizer decides best execution plan
-- → Performance difference = negligible!

-- When CTE is BETTER:
-- 1. Multiple times use:
WITH summary AS (
  SELECT rep_id, SUM(amount) AS total
  FROM sales GROUP BY rep_id
)
-- Use summary twice → calculated once! ✅
SELECT * FROM summary WHERE total > 15000
UNION ALL
SELECT * FROM summary WHERE total < 5000;

-- 2. Complex multi-step logic:
WITH step1 AS (...),
     step2 AS (...),
     step3 AS (...)
SELECT * FROM step3;
-- Each step clear → easy to debug! ✅

-- 3. Production/team code:
-- → Readable after 6 months too!
-- → Easy to maintain!

-- When SUBQUERY is BETTER:
-- 1. Simple one-time use:
SELECT dept, avg_sal
FROM (
  SELECT dept, AVG(salary) AS avg_sal
  FROM employees GROUP BY dept
) AS dept_summary
WHERE avg_sal > 60000;
-- Simple → no need for CTE!

-- 2. EXISTS/NOT EXISTS checks:
WHERE EXISTS (SELECT 1 FROM orders o
              WHERE o.customer_id = c.customer_id)
-- Natural fit for subquery! ✅

-- 3. Scalar value filter:
WHERE salary > (SELECT AVG(salary) FROM employees)
-- Single value → subquery perfect! ✅

-- DECISION RULE:
-- ┌────────────────────────┬────────────────────┐
-- │ Use CTE when           │ Use Subquery when  │
-- ├────────────────────────┼────────────────────┤
-- │ Multiple times use     │ One time use       │
-- │ Multi-step complex     │ Simple one-step    │
-- │ Production/team code   │ Quick query        │
-- │ Debugging important    │ EXISTS/NOT EXISTS  │
-- │ Recursive logic needed │ Scalar value       │
-- │ Long term maintenance  │ Quick inline filter│
-- └────────────────────────┴────────────────────┘

-- =============================================
-- NOTE 4: CTE MATERIALIZATION
-- =============================================

-- WHAT IS MATERIALIZATION?
-- CTE result calculated ONCE → stored in memory
-- → Reused whenever CTE is referenced
-- Like making sauce once → use from bowl!

-- PostgreSQL 12+ behavior:
-- → Default: CTE inlined (optimizer decides)
-- → MATERIALIZED keyword: force store in memory
-- → NOT MATERIALIZED keyword: force inline

-- Force materialization:
WITH summary AS MATERIALIZED (
  SELECT rep_id, SUM(amount) AS total
  FROM sales GROUP BY rep_id
)
SELECT * FROM summary;

-- Force inline:
WITH summary AS NOT MATERIALIZED (
  SELECT rep_id, SUM(amount) AS total
  FROM sales GROUP BY rep_id
)
SELECT * FROM summary;

-- Materialization GOOD when:
-- 1. CTE used multiple times
-- 2. Expensive calculation
-- 3. Need consistent results

-- Materialization BAD when:
-- 1. CTE used only once
-- 2. Filter can be pushed inside CTE
-- 3. CTE is small/simple

-- BAD example:
WITH all_data AS (
  SELECT * FROM sales  -- 1M rows stored!
)
SELECT * FROM all_data WHERE region = 'North';
-- Materializes 1M rows → filters after! ❌

-- GOOD example:
WITH north_sales AS (
  SELECT * FROM sales
  WHERE region = 'North'  -- filter inside! ✅
)
SELECT * FROM north_sales;

-- =============================================
-- NOTE 5: SUBQUERY SINGLE COLUMN RULE
-- =============================================

-- MOST COMMON MISTAKE!
-- Subquery in WHERE/SELECT → SINGLE column only!

-- ❌ WRONG → multiple columns!
WHERE salary > (SELECT dept, AVG(salary) FROM employees)
-- ERROR: subquery returns multiple columns!

-- ✅ CORRECT → single column!
WHERE salary > (SELECT AVG(salary) FROM employees)

-- Test yourself before writing:
-- "How many columns does my subquery return?"
-- If > 1 → ERROR!

-- FROM clause is exception:
-- FROM (SELECT col1, col2 FROM ...) AS alias
-- Multiple columns OK in FROM! ✅
-- Alias is REQUIRED! ✅

-- =============================================
-- NOTE 6: MULTIPLE CTEs CHAINING RULES
-- =============================================

-- RULES:
-- 1. Only ONE WITH keyword!
-- 2. CTEs separated by commas!
-- 3. Later CTE can reference earlier CTE!
-- 4. Earlier CTE CANNOT reference later CTE!
-- 5. No comma after LAST CTE!

-- ✅ Correct syntax:
WITH cte1 AS (          -- first CTE
  SELECT dept, AVG(salary) AS avg_sal
  FROM employees GROUP BY dept
),                      -- comma!
cte2 AS (               -- can use cte1!
  SELECT * FROM cte1
  WHERE avg_sal > 60000
),                      -- comma!
cte3 AS (               -- can use cte1 and cte2!
  SELECT c.*, e.name
  FROM cte2 c
  JOIN employees e ON c.dept = e.dept
)                       -- NO comma!
SELECT * FROM cte3;     -- final query

-- ❌ Common mistakes:
WITH cte1 AS (...),
WITH cte2 AS (...)  -- ❌ Double WITH!

WITH cte1 AS (...),
     cte2 AS (SELECT * FROM cte3)  -- ❌ cte3 not defined yet!

WITH cte1 AS (...),
     cte2 AS (...)  -- ❌ trailing comma before SELECT!
SELECT * FROM cte2;

-- =============================================
-- NOTE 7: EXISTS vs IN — KEY DIFFERENCES
-- =============================================

-- IN:
-- → Builds complete list first
-- → Then compares each row against list
-- → NULL in list → SILENT FAILURE!
-- → Scans all matches

-- EXISTS:
-- → Checks existence row by row
-- → Short circuits on FIRST match → FASTER!
-- → NULL safe ✅
-- → Correlated by nature

-- NOT IN NULL TRAP:
-- orders has NULL customer_id
-- NOT IN (1, 2, 3, NULL) expands to:
--   customer_id != 1
--   AND customer_id != 2
--   AND customer_id != 3
--   AND customer_id != NULL ← UNKNOWN!
-- UNKNOWN → entire WHERE = UNKNOWN
-- Result = ZERO rows! Silent bug! 😱

-- ALWAYS prefer NOT EXISTS over NOT IN!

-- =============================================
-- NOTE 8: CLASSIC INTERVIEW PROBLEMS
-- =============================================

-- 2nd Highest Salary — Best way:
WITH ranked AS (
  SELECT salary,
    DENSE_RANK() OVER(ORDER BY salary DESC) AS rnk
    -- No PARTITION BY → overall ranking!
  FROM employees
)
SELECT DISTINCT salary FROM ranked WHERE rnk = 2;

-- Why DENSE_RANK not RANK?
-- Salaries: 95000, 90000, 90000, 85000
-- RANK():       1,     2,     2,     4 ← gap! ❌
-- DENSE_RANK(): 1,     2,     2,     3 ← no gap! ✅

-- Nth Highest Salary (Generic):
WITH ranked AS (
  SELECT salary,
    DENSE_RANK() OVER(ORDER BY salary DESC) AS rnk
  FROM employees
)
SELECT DISTINCT salary FROM ranked WHERE rnk = N;
-- Just change N!

-- Employees > Dept Average:
SELECT name, dept, salary
FROM employees e1
WHERE salary > (
  SELECT AVG(salary) FROM employees e2
  WHERE e2.dept = e1.dept  -- correlated!
);

-- More than ALL in a group:
SELECT name FROM employees
WHERE salary > ALL (
  SELECT salary FROM employees WHERE dept = 'HR'
);
-- Same as: WHERE salary > (SELECT MAX(salary)...)

---- =============================================
-- SENIOR INTERVIEW SENTENCES
-- =============================================

-- On CTE vs Subquery:
-- "In modern PostgreSQL, the performance difference
--  between CTE and subquery is negligible because
--  the optimizer handles both similarly. I prefer
--  CTEs for readability and maintainability,
--  especially in production pipelines. I use
--  subqueries when the logic is simple or when
--  I need an EXISTS check."

-- On Materialization:
-- "CTE materialization means the result is
--  calculated once, stored in memory, and reused
--  across multiple references. In PostgreSQL 12+,
--  the optimizer automatically decides whether to
--  materialize. I explicitly use the MATERIALIZED
--  keyword when the same expensive CTE is called
--  multiple times in a query."

-- On Correlated Subquery Performance:
-- "A correlated subquery executes once for every
--  row in the outer table — N rows means N executions.
--  For large tables, I always prefer CTEs or JOINs
--  for better performance. A correlated subquery with
--  EXISTS is acceptable because it short-circuits on
--  the first match."

-- On Subquery Single Column Rule:
-- "A subquery used with comparison operators can only
--  return a single column. A multi-column subquery
--  belongs in the FROM clause as a derived table —
--  and an alias is always required."

-- On Multiple CTEs:
-- "Multiple CTEs follow a simple rule — only one WITH
--  keyword, CTEs separated by commas, and later CTEs
--  can reference earlier ones but not vice versa.
--  This creates a clean pipeline-like structure where
--  each CTE handles one specific calculation step."

-- On EXISTS vs IN:
-- "I always prefer NOT EXISTS over NOT IN because
--  NOT IN silently returns zero rows when the subquery
--  contains any NULL value. NOT EXISTS is NULL safe
--  and short-circuits on the first match, making it
--  both safer and faster on large datasets."

-- On Classic Problems:
-- "For finding the Nth highest salary, I use
--  DENSE_RANK() without PARTITION BY for overall
--  ranking. DENSE_RANK is preferred over RANK
--  because it has no gaps in ranking when ties exist,
--  ensuring the Nth rank always returns a result."

-- On Row vs Group vs Scalar comparisons:
-- "Before writing a subquery, I identify what type
--  of comparison I need: Row vs Scalar uses a
--  non-correlated subquery, Row vs Group uses a
--  correlated subquery, and Group vs Group uses
--  a CTE with WHERE. This mental model helps me
--  choose the right approach instantly."
