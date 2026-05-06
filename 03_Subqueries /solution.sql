-- =============================================
-- SUBQUERIES & CTEs — SOLUTIONS
-- =============================================
-- Format: Topic → Solution + Key Points
-- =============================================

-- =============================================
-- TOPIC 1: SCALAR SUBQUERY
-- =============================================

-- Q1. Each employee with company average:
SELECT
  name,
  salary,
  (SELECT AVG(salary) FROM employees) AS company_avg,
  salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;
-- Scalar subquery runs ONCE → same value every row!
-- Ivan (NULL salary) → diff = NULL (NULL math!)

-- Q2. Employees above company average:

-- Using WHERE subquery:
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Using CTE:
WITH company_avg AS (
  SELECT AVG(salary) AS avg_salary
  FROM employees
)
SELECT e.name, e.salary
FROM employees e
CROSS JOIN company_avg ca
WHERE e.salary > ca.avg_salary;
-- CROSS JOIN with single row CTE → clean pattern!

-- Q3. Difference:
-- Query A → company wide average (fixed value)
--   AVG = 73333 → same for everyone
-- Query B → Tech dept average only
--   AVG = 71250 → different from company avg!
-- Query B is NON-correlated but dept specific!

-- Q4. Ivan (NULL salary):
-- NULL > 73333 = UNKNOWN
-- UNKNOWN rows filtered out automatically!
-- Ivan excluded from result ✅

-- KEY POINTS:
-- Scalar subquery → single value, runs once!
-- CROSS JOIN with single row CTE → clean pattern!
-- NULL > value = UNKNOWN → excluded!
-- SELECT alias cannot be reused in same query!

-- =============================================
-- TOPIC 2: CORRELATED SUBQUERY
-- =============================================

-- Q1. Employees above dept average:
SELECT name, dept, salary
FROM employees e1
WHERE salary > (
  SELECT AVG(salary)
  FROM employees e2
  WHERE e2.dept = e1.dept  -- correlated!
);
-- Runs 10 times for 10 employees!
-- Each row gets its own dept average!

-- Q2. Employees above their manager:
SELECT e1.name, e1.salary
FROM employees e1
WHERE e1.salary > (
  SELECT e2.salary
  FROM employees e2
  WHERE e2.emp_id = e1.manager_id
);
-- e1 = current employee
-- e2 = manager
-- e2.emp_id = e1.manager_id → find manager!

-- Q3. Execution difference:
-- Non-Correlated → runs ONCE → fixed value
-- Correlated → runs N times → different per row
-- 10 employees → correlated runs 10 times!
-- 1M employees → runs 1M times! → SLOW!

-- Q4. Performance problem + when to use:
-- Problem: N rows = N executions → slow on large data!
-- Still use when:
-- → EXISTS checks (short circuits!)
-- → Row level comparison needed
-- → Small tables
-- → JOIN cannot express the logic

-- KEY POINTS:
-- Correlated = outer reference in inner query!
-- N rows = N executions → avoid on large tables!
-- Replace with CTE + JOIN for better performance!
-- EXISTS correlated → acceptable (short circuits)!

-- =============================================
-- TOPIC 3: SUBQUERY PLACEMENT
-- =============================================

-- Q1. WHERE subquery:
SELECT order_id, amount
FROM orders
WHERE amount > (SELECT AVG(amount) FROM orders);

-- Q2. FROM subquery (derived table):
SELECT customer_id, total_spent
FROM (
  SELECT customer_id, SUM(amount) AS total_spent
  FROM orders GROUP BY customer_id
) AS customer_summary        -- alias REQUIRED!
WHERE total_spent > (
  SELECT AVG(total_spent)
  FROM (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM orders GROUP BY customer_id
  ) AS avg_calc
);

-- Q3. SELECT subquery:
SELECT
  order_id,
  amount,
  (SELECT AVG(amount) FROM orders) AS overall_avg,
  amount - (SELECT AVG(amount) FROM orders) AS diff
FROM orders;

-- Q4. Wrong query explanation:
-- WHERE total > 1000 → ERROR!
-- total is SELECT alias
-- WHERE runs BEFORE SELECT!
-- total doesn't exist yet at WHERE stage!

-- Q5. Three correct versions:

-- Using FROM subquery:
SELECT customer_id, total
FROM (
  SELECT customer_id, SUM(amount) AS total
  FROM orders GROUP BY customer_id
) AS summary
WHERE total > 1000;

-- Using HAVING (simplest!):
SELECT customer_id, SUM(amount) AS total
FROM orders
GROUP BY customer_id
HAVING SUM(amount) > 1000;

-- Using CTE (most readable!):
WITH customer_totals AS (
  SELECT customer_id, SUM(amount) AS total
  FROM orders GROUP BY customer_id
)
SELECT customer_id, total
FROM customer_totals
WHERE total > 1000;

-- KEY POINTS:
-- WHERE subquery → single column only!
-- FROM subquery → alias REQUIRED!
-- SELECT subquery → scalar only!
-- HAVING → aggregate filter after GROUP BY!
-- CTE → most readable for complex logic!

-- =============================================
-- TOPIC 4: EXISTS vs IN
-- =============================================

-- Q1. Customers who placed orders:

-- Using IN:
SELECT name FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- Using EXISTS ✅ (preferred!):
SELECT name FROM customers c
WHERE EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
);

-- Q2. Customers who never placed orders:

-- NOT IN ⚠️ DANGEROUS:
SELECT name FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM orders);
-- If ANY NULL in orders → returns ZERO rows!

-- NOT EXISTS ✅ safest:
SELECT name FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
);

-- LEFT JOIN + NULL ✅:
SELECT c.name FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- Q3. NULL trap:
-- NOT IN (1, 2, 3, NULL) expands to:
-- customer_id != 1
-- AND customer_id != 2
-- AND customer_id != 3
-- AND customer_id != NULL ← UNKNOWN!
-- UNKNOWN → entire WHERE = UNKNOWN
-- Result = ZERO rows! Silent bug! 😱

-- Q4. EXISTS faster because:
-- EXISTS stops at FIRST match found!
-- IN scans ALL matching rows!
-- EXISTS = short circuit evaluation!
-- On large tables → EXISTS significantly faster!

-- KEY POINTS:
-- EXISTS → NULL safe, short circuits ✅
-- NOT IN → breaks with NULLs! ⚠️
-- NOT EXISTS → always preferred over NOT IN!
-- EXISTS for existence → always best choice!

-- =============================================
-- TOPIC 5: CLASSIC PROBLEMS
-- =============================================

-- Q1. 2nd Highest Salary:

-- Method 1: Subquery
SELECT MAX(salary) FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Method 2: DENSE_RANK (Best!)
WITH ranked AS (
  SELECT salary,
    DENSE_RANK() OVER(ORDER BY salary DESC) AS rnk
  FROM employees
)
SELECT DISTINCT salary FROM ranked WHERE rnk = 2;

-- Method 3: LIMIT OFFSET
SELECT DISTINCT salary FROM employees
ORDER BY salary DESC LIMIT 1 OFFSET 1;

-- Q2. Employees above dept average:
SELECT name, dept, salary
FROM employees e1
WHERE salary > (
  SELECT AVG(salary) FROM employees e2
  WHERE e2.dept = e1.dept
);

-- Q3. Nth highest (N=3):
WITH ranked AS (
  SELECT salary,
    DENSE_RANK() OVER(ORDER BY salary DESC) AS rnk
  FROM employees
)
SELECT DISTINCT salary FROM ranked WHERE rnk = 3;
-- Change rnk = N for any N!

-- Q4. Departments where avg > company avg:
WITH dept_avg AS (
  SELECT dept, AVG(salary) AS dept_average
  FROM employees GROUP BY dept
)
SELECT dept, dept_average
FROM dept_avg
WHERE dept_average > (SELECT AVG(salary) FROM employees);

-- Q5. More than ALL HR employees:
SELECT name, dept, salary FROM employees
WHERE salary > ALL (
  SELECT salary FROM employees WHERE dept = 'HR'
);
-- Same as:
WHERE salary > (SELECT MAX(salary) FROM employees
                WHERE dept = 'HR')

-- KEY POINTS:
-- DENSE_RANK → no gaps with ties → use for Nth!
-- RANK → gaps after ties → avoid for Nth!
-- ALL → same as > MAX!
-- ANY → same as > MIN!

-- =============================================
-- TOPIC 6: CTE vs SUBQUERY vs DERIVED TABLE
-- =============================================

-- Q1. Three ways for region sales > 30000:

-- Derived Table:
SELECT region, total
FROM (
  SELECT region, SUM(amount) AS total
  FROM sales GROUP BY region
) AS region_summary          -- alias REQUIRED!
WHERE total > 30000;

-- CTE (most readable!):
WITH region_summary AS (
  SELECT region, SUM(amount) AS total
  FROM sales GROUP BY region
)
SELECT region, total
FROM region_summary
WHERE total > 30000;

-- Subquery in HAVING (simplest!):
SELECT region, SUM(amount) AS total
FROM sales
GROUP BY region
HAVING SUM(amount) > 30000;

-- Q2. CTE vs Subquery examples:

-- Use CTE when:
-- 1. Multiple times reference needed
WITH summary AS (SELECT rep_id, SUM(amount) AS total FROM sales GROUP BY rep_id)
SELECT * FROM summary WHERE total > 15000
UNION ALL
SELECT * FROM summary WHERE total < 5000;

-- 2. Complex multi-step logic
WITH step1 AS (...), step2 AS (...), step3 AS (...)
SELECT * FROM step3;

-- 3. Production readable code
-- Use Subquery when:
-- 1. Simple one-time use
SELECT * FROM (SELECT dept, AVG(salary) AS avg FROM employees GROUP BY dept) s WHERE avg > 60000;
-- 2. EXISTS checks
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
-- 3. Scalar value
WHERE salary > (SELECT AVG(salary) FROM employees)

-- Q3. Yes! CTE can reference itself → Recursive CTE!
-- Uses RECURSIVE keyword + Anchor + Recursive members!

-- Q4. Two problems:
-- Problem 1: Double WITH keyword → ERROR!
-- Problem 2: Trailing comma after avg_sal → ERROR!
-- Fix: Single WITH, comma between CTEs, no trailing comma!

-- Q5. Two chained CTEs:
WITH sales_summary AS (
  SELECT region, SUM(amount) AS total
  FROM sales GROUP BY region
),
region_filter AS (
  SELECT region FROM sales_summary
  WHERE total > 30000
)
SELECT * FROM region_filter;

-- KEY POINTS:
-- Derived table → alias REQUIRED!
-- CTE → reusable in same query!
-- HAVING → simplest for group filter!
-- Double WITH → ERROR! Single WITH only!

-- =============================================
-- TOPIC 7: MULTIPLE CTEs CHAINING
-- =============================================

-- Q1. Three chained CTEs:
WITH dept_summary AS (
  SELECT dept, AVG(salary) AS dept_avg
  FROM employees GROUP BY dept
),
company_summary AS (
  SELECT AVG(salary) AS company_avg
  FROM employees
),
performance_label AS (
  SELECT
    e.name, e.dept, e.salary,
    ds.dept_avg,
    cs.company_avg,
    CASE
      WHEN e.salary > ds.dept_avg
       AND e.salary > cs.company_avg THEN 'High'
      WHEN e.salary > ds.dept_avg
       OR  e.salary > cs.company_avg THEN 'Good'
      ELSE 'Average'
    END AS performance
  FROM employees e
  JOIN dept_summary ds ON e.dept = ds.dept
  CROSS JOIN company_summary cs
)
SELECT * FROM performance_label;
-- CROSS JOIN for single row CTE → every row gets company_avg!

-- Q2. Execution order:
-- CTE1 → CTE2 → CTE3 → SELECT
-- Top to bottom order!
-- Each CTE can use previously defined CTEs!

-- Q3. CTE reference rules:
-- cte2 CAN reference cte1 ✅ (defined before!)
-- cte1 CANNOT reference cte2 ❌ (not defined yet!)

-- Q4. Two problems:
-- Problem 1: Double WITH keyword → ERROR!
-- Problem 2: Trailing comma after avg_sal → ERROR!

-- KEY POINTS:
-- Single WITH, comma separated CTEs!
-- Forward reference only!
-- CROSS JOIN for single row CTE!
-- No comma after last CTE!

-- =============================================
-- TOPIC 8: SUBQUERY vs JOIN PERFORMANCE
-- =============================================

-- Q1. Customers with completed orders:

-- EXISTS ✅ (preferred!):
SELECT c.name FROM customers c
WHERE EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
  AND o.status = 'completed'
);

-- JOIN:
SELECT DISTINCT c.name
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed';
-- DISTINCT needed to remove duplicates!

-- Q2. EXISTS faster because:
-- Short circuits on first match!
-- No duplicate explosion!
-- No DISTINCT needed!
-- JOIN → all matches found → DISTINCT adds overhead!

-- Q3. Total orders > 500:

-- Correlated (slow on large data!):
SELECT c.name
FROM customers c
WHERE (
  SELECT SUM(o.amount) FROM orders o
  WHERE o.customer_id = c.customer_id
) > 500;

-- JOIN + GROUP BY (faster!):
SELECT c.name, SUM(o.amount) AS total
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING SUM(o.amount) > 500;
-- JOIN scans once → GROUP BY → HAVING filter!
-- Correlated scans N times → much slower!

-- Q4. "Subquery always slower" → MYTH!
-- EXISTS subquery FASTER than JOIN + DISTINCT!
-- Modern PostgreSQL optimizer often makes same plan!
-- EXISTS → best for existence checks always!

-- KEY POINTS:
-- EXISTS → short circuits → faster than JOIN for existence!
-- JOIN + GROUP BY → faster than correlated for aggregation!
-- Modern PostgreSQL → optimizer often same execution plan!
-- Readability first → optimize only when needed!

-- =============================================
-- TOPIC 9: CTE READABILITY vs PERFORMANCE
-- =============================================

-- Q1. Two ways:

-- Nested subqueries (hard to read!):
SELECT rep_id FROM sales s1
WHERE (
  SELECT SUM(CASE WHEN category='Electronics'
             THEN amount ELSE 0 END)
  FROM sales s2 WHERE s1.rep_id = s2.rep_id
) > (SELECT AVG(amount) FROM sales);

-- CTE (readable!):
WITH sales_calc AS (
  SELECT rep_id,
    SUM(CASE WHEN category='Electronics'
        THEN amount ELSE 0 END) AS elec_sales
  FROM sales GROUP BY rep_id
),
company_avg AS (
  SELECT AVG(amount) AS avg_sales FROM sales
)
SELECT sc.rep_id
FROM sales_calc sc
CROSS JOIN company_avg ca
WHERE sc.elec_sales > ca.avg_sales;

-- Q2. CTE materialization:
-- Result calculated ONCE → stored in memory → reused!
-- PostgreSQL 12+ → auto inline (optimizer decides!)
-- MATERIALIZED → force store in memory
-- NOT MATERIALIZED → force inline

-- Q3. Performance difference:
-- PostgreSQL 12+ → same execution plan mostly!
-- Optimizer inlines CTE → same as subquery!
-- Performance difference = negligible!
-- Focus on READABILITY!

-- Q4. CTE vs Subquery examples:
-- CTE: multiple use, multi-step, production code, recursive!
-- Subquery: one-time, simple, EXISTS, scalar value!

-- KEY POINTS:
-- Modern PostgreSQL → CTE and subquery same performance!
-- CTE → readability + maintainability priority!
-- MATERIALIZED → force when CTE used multiple times!
-- Readability > micro-optimization always!

-- =============================================
-- TOPIC 10: RECURSIVE CTE
-- =============================================

-- Q1. Org hierarchy:
WITH RECURSIVE emp_hierarchy AS (
  -- Anchor Member: CEO
  SELECT emp_id, name, manager_id, 1 AS level
  FROM employees WHERE manager_id IS NULL

  UNION ALL

  -- Recursive Member: each level's reports
  SELECT e.emp_id, e.name, e.manager_id, eh.level + 1
  FROM employees e
  JOIN emp_hierarchy eh ON e.manager_id = eh.emp_id
  WHERE eh.level < 10  -- infinite loop prevention!
)
SELECT * FROM emp_hierarchy ORDER BY level, emp_id;

-- Q2. Two parts:
-- Anchor Member → starting point, runs ONCE
--   WHERE manager_id IS NULL → CEO!
-- Recursive Member → references CTE itself
--   JOIN emp_hierarchy → self reference!
--   Runs repeatedly until no new rows!

-- Q3. Infinite loop prevention:
-- WHERE level < N in recursive member!
-- PostgreSQL 14+: CYCLE keyword detects cycles!
-- Data cycles → employee is own manager!
-- Bad conditions → WHERE never false!

-- Q4. All subordinates of Bob (emp_id=2):
WITH RECURSIVE bob_subordinates AS (
  -- Anchor: start from Bob
  SELECT emp_id, name, manager_id, 1 AS level
  FROM employees WHERE emp_id = 2

  UNION ALL

  -- Recursive: Bob's reports' reports
  SELECT e.emp_id, e.name, e.manager_id, bs.level + 1
  FROM employees e
  JOIN bob_subordinates bs ON e.manager_id = bs.emp_id
)
SELECT name, level FROM bob_subordinates
WHERE emp_id != 2  -- exclude Bob himself!
ORDER BY level, name;

-- KEY POINTS:
-- RECURSIVE keyword required!
-- Anchor = starting point (runs once)!
-- Recursive = self reference (runs repeatedly)!
-- UNION ALL between anchor and recursive!
-- Always add level limit to prevent infinite loop!

-- =============================================
-- TOPIC 11: CTE MATERIALIZATION
-- =============================================

-- Q1. Materialization = calculate once, store, reuse!
-- Good when: CTE used multiple times, expensive calc!
-- Bad when: CTE used once, filter can be pushed inside!

-- Q2. Force materialization:
WITH summary AS MATERIALIZED (
  SELECT rep_id, SUM(amount) AS total
  FROM sales GROUP BY rep_id
)
SELECT * FROM summary WHERE total > 15000
UNION ALL
SELECT * FROM summary WHERE total < 5000;
-- MATERIALIZED keyword forces storage!
-- Calculated ONCE → used twice! ✅

-- Q3. When to use MATERIALIZED:
-- Same expensive CTE referenced multiple times!
-- Consistent results needed across references!
-- PostgreSQL 12+ default = auto inline!

-- KEY POINTS:
-- PostgreSQL 12+ → auto inline by default!
-- MATERIALIZED → force store in memory!
-- NOT MATERIALIZED → force inline!
-- Multiple references → MATERIALIZED beneficial!

-- =============================================
-- TOPIC 12: CTE vs TEMP TABLE vs VIEW
-- =============================================

-- Q1. ETL pipeline → TEMP TABLE!
CREATE TEMP TABLE staged_data AS
SELECT * FROM raw_orders WHERE status = 'valid';
CREATE INDEX ON staged_data(customer_id);  -- indexable!
-- Multiple queries use same temp table in session!
-- Index speeds up subsequent queries!

-- Q2. Business team interface → VIEW!
CREATE VIEW sales_dashboard AS
SELECT c.name, COUNT(o.order_id) AS orders,
  SUM(o.amount) AS revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name;
-- Anyone can: SELECT * FROM sales_dashboard!
-- Complex JOIN hidden from users! ✅

-- Q3. View vs Materialized View:
-- View:
--   → Virtual table, query stored not data
--   → Always fresh data ✅
--   → Slow on complex queries ⚠️
--   → Cannot be indexed directly

-- Materialized View:
--   → Physical data stored ✅
--   → Fast queries ✅
--   → Can be indexed ✅
--   → Stale data risk ⚠️
--   → Needs REFRESH ⚠️
REFRESH MATERIALIZED VIEW sales_dashboard;

-- Q4. "Always use Temp Tables" → WRONG!
-- CTE better when:
-- → Single query only (no DDL overhead!)
-- → Small/medium data
-- → Recursive logic needed (Temp Table cannot!)
-- → Readability important

-- KEY POINTS:
-- CTE → single query, no storage, no DDL!
-- Temp Table → session-wide, indexable, ETL!
-- View → permanent, always fresh, business layer!
-- Mat. View → fast, physical, needs REFRESH!

-- =============================================
-- TOPIC 13: PERFORMANCE IMPLICATIONS
-- =============================================

-- Q1. Five key performance rules:

-- Rule 1: Filter EARLY
SELECT * FROM (
  SELECT * FROM orders
  WHERE status = 'completed'  -- filter inside! ✅
) AS completed_orders;
-- NOT: SELECT * FROM (SELECT * FROM orders) WHERE status='completed'

-- Rule 2: EXISTS > IN for existence checks
WHERE EXISTS (SELECT 1 FROM orders o
              WHERE o.customer_id = c.customer_id)
-- Short circuits on first match!

-- Rule 3: Replace correlated with CTE/JOIN
WITH dept_avg AS (
  SELECT dept, AVG(salary) AS avg_sal
  FROM employees GROUP BY dept
)
SELECT e.name FROM employees e
JOIN dept_avg d ON e.dept = d.dept
WHERE e.salary > d.avg_sal;
-- One scan vs N scans!

-- Rule 4: Avoid SELECT *
SELECT name, salary  -- ✅ only needed columns!
-- NOT: SELECT *     -- ❌ unnecessary data transfer!

-- Rule 5: Avoid functions on indexed columns
-- ❌ Slow → function prevents index use!
WHERE EXTRACT(YEAR FROM order_date) = 2023
-- ✅ Fast → range scan uses index!
WHERE order_date >= '2023-01-01'
AND order_date < '2024-01-01'

-- Q2. Replace slow correlated:
-- ❌ Slow:
WHERE salary > (SELECT AVG(salary) FROM employees e2
                WHERE e2.dept = e1.dept)

-- ✅ Fast CTE:
WITH dept_avg AS (
  SELECT dept, AVG(salary) AS avg_sal
  FROM employees GROUP BY dept
)
SELECT e.name, e.salary
FROM employees e
JOIN dept_avg d ON e.dept = d.dept
WHERE e.salary > d.avg_sal;

-- Q3. Function on indexed column:
-- EXTRACT(YEAR FROM order_date) = 2023
-- Creates computed value → index not used!
-- Fix: Use range scan instead!
WHERE order_date >= '2023-01-01'
AND order_date < '2024-01-01'

-- Q4. Senior level optimization approach:
-- Step 1: Identify slow query using EXPLAIN ANALYZE
-- Step 2: Check if filtering early possible
-- Step 3: Replace correlated subquery with CTE/JOIN
-- Step 4: Check if EXISTS better than IN
-- Step 5: Remove SELECT *, add specific columns
-- Step 6: Check function usage on indexed columns
-- Step 7: Verify indexes exist on JOIN/WHERE columns
-- Never: premature optimization without measurement!

-- =============================================
-- KEY TAKEAWAYS — SUBQUERIES & CTEs
-- =============================================

-- 1. WHERE/SELECT subquery → single column only!
-- 2. FROM subquery → alias REQUIRED!
-- 3. NOT EXISTS > NOT IN → NULL safe!
-- 4. EXISTS short circuits → faster than IN!
-- 5. Correlated = N executions → avoid on large tables!
-- 6. Single WITH keyword → comma separated CTEs!
-- 7. Later CTE can reference earlier CTE!
-- 8. Recursive CTE → always add level limit!
-- 9. PostgreSQL 12+ → CTE auto inlined!
-- 10. MATERIALIZED → force store for multiple use!
-- 11. CTE → single query | Temp Table → ETL pipeline!
-- 12. View → business layer | Mat.View → performance!
-- 13. Filter early → EXISTS over IN → CTE over correlated!
-- 14. Avoid SELECT * and functions on indexed columns!
-- 15. DENSE_RANK → Nth highest (no gaps with ties)!
-- 16. ALL → same as > MAX | ANY → same as > MIN!
-- 17. Readability > micro-optimization always!
