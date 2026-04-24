-- =============================================
-- SUBQUERIES & CTEs — COMPLETE CONCEPTS
-- =============================================

-- =============================================
-- 1. WHAT IS A SUBQUERY?
-- =============================================

-- A query inside another query
-- Three types based on behavior:
--   1. Scalar    → returns single value
--   2. Correlated → references outer query
--   3. Non-Correlated → independent

-- Three placements:
--   1. WHERE clause
--   2. FROM clause  (Derived Table)
--   3. SELECT clause

-- =============================================
-- 2. SCALAR SUBQUERY
-- =============================================

-- THEORY:
-- → Returns exactly ONE value
-- → Runs only ONCE
-- → Can be used in SELECT, WHERE, HAVING
-- → Acts like a fixed value for every row

-- EXAMPLE 1: Show each employee with company average
SELECT
  name,
  salary,
  (SELECT AVG(salary) FROM employees) AS company_avg,
  salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;

-- Output:
-- name    | salary | company_avg | diff_from_avg
-- --------|--------|-------------|---------------
-- Alice   | 80000  | 73333       | +6667
-- Bob     | 60000  | 73333       | -13333
-- Charlie | 90000  | 73333       | +16667

-- EXAMPLE 2: Employees earning above company average
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- =============================================
-- 3. CORRELATED SUBQUERY
-- =============================================

-- THEORY:
-- → References outer query column
-- → Runs N times (once per outer row)
-- → Each row gets its own inner result
-- → Slower on large tables
-- → Use when row-specific comparison needed

-- EXAMPLE 1: Employees earning more than dept average
SELECT name, dept, salary
FROM employees e1
WHERE salary > (
  SELECT AVG(salary)
  FROM employees e2
  WHERE e2.dept = e1.dept  -- outer reference → correlated!
);

-- Execution flow:
-- Row 1 Alice (Tech)   → calculate Tech avg   → compare
-- Row 2 Bob (Tech)     → calculate Tech avg   → compare
-- Row 3 Charlie (Tech) → calculate Tech avg   → compare
-- Row 4 David (HR)     → calculate HR avg     → compare
-- Total = 10 executions for 10 rows!

-- EXAMPLE 2: Employees earning more than their manager
SELECT e1.name, e1.salary
FROM employees e1
WHERE e1.salary > (
  SELECT e2.salary
  FROM employees e2
  WHERE e2.emp_id = e1.manager_id
-- e1 = current employee (primary)
-- e2 = manager (secondary)
-- e2.emp_id = e1.manager_id → find the manager!
);

-- =============================================
-- 4. NON-CORRELATED SUBQUERY
-- =============================================

-- THEORY:
-- → Independent of outer query
-- → Runs only ONCE
-- → Returns fixed value/list
-- → Faster than correlated!

-- EXAMPLE: Employees above company average
SELECT name, salary
FROM employees
WHERE salary > (
  SELECT AVG(salary) FROM employees
  -- No reference to outer query → runs once!
);

-- =============================================
-- 5. SUBQUERY PLACEMENT RULES
-- =============================================

-- RULE 1: WHERE clause → SINGLE column only!
-- ✅ Correct
SELECT name FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- ❌ Wrong → multiple columns!
SELECT name FROM employees
WHERE salary > (SELECT dept, AVG(salary) FROM employees);

-- RULE 2: FROM clause → multiple columns okay
--         BUT alias is REQUIRED!
-- ✅ Correct
SELECT dept, avg_sal
FROM (
  SELECT dept, AVG(salary) AS avg_sal
  FROM employees
  GROUP BY dept
) AS dept_summary       -- alias zaruri!
WHERE avg_sal > 60000;

-- ❌ Wrong → no alias!
SELECT dept, avg_sal
FROM (
  SELECT dept, AVG(salary) AS avg_sal
  FROM employees
  GROUP BY dept
)                       -- missing alias → error!
WHERE avg_sal > 60000;

-- RULE 3: SELECT clause → scalar only!
-- ✅ Correct
SELECT
  name,
  salary,
  (SELECT AVG(salary) FROM employees) AS company_avg
FROM employees;

-- =============================================
-- 6. EXISTS vs IN
-- =============================================

-- THEORY:
-- Both check existence but behave differently!

-- IN:
-- → Builds a list first: (1, 2, 3, NULL)
-- → Then compares each row
-- → NULL in list → SILENT FAILURE! ⚠️
-- → Scans all matches

-- EXISTS:
-- → Checks existence row by row
-- → Short circuits on first match → FASTER!
-- → NULL safe ✅
-- → Correlated by nature

-- EXAMPLE: Customers who placed orders

-- Using IN
SELECT name FROM customers
WHERE customer_id IN (
  SELECT customer_id FROM orders
);

-- Using EXISTS ✅ (preferred!)
SELECT name FROM customers c
WHERE EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
);

-- ANTI JOIN comparison:

-- NOT IN → DANGEROUS with NULLs!
SELECT name FROM customers
WHERE customer_id NOT IN (
  SELECT customer_id FROM orders
  -- If ANY NULL exists here:
  -- NOT IN (1, 2, NULL)
  -- customer_id != NULL = UNKNOWN
  -- Returns ZERO rows! Silent bug! 😱
);

-- NOT EXISTS → Always safe! ✅
SELECT name FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
);

-- LEFT JOIN + NULL → Also safe! ✅
SELECT c.name
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- =============================================
-- 7. ALL vs ANY
-- =============================================

-- THEORY:
-- ALL → compare with every value in list
-- ANY → compare with at least one value

-- ALL → same as > MAX()
SELECT name, salary FROM employees
WHERE salary > ALL (
  SELECT salary FROM employees
  WHERE dept = 'HR'
);
-- HR salaries: 50000, 70000, 85000
-- salary > ALL = salary > 85000 (max!)

-- ANY → same as > MIN()
SELECT name, salary FROM employees
WHERE salary > ANY (
  SELECT salary FROM employees
  WHERE dept = 'HR'
);
-- salary > ANY = salary > 50000 (min!)

-- =============================================
-- 8. WHEN TO USE WHAT
-- =============================================

-- DECISION TABLE:
-- ┌─────────────────┬─────────────────────────────┐
-- │ Comparison      │ Use                         │
-- ├─────────────────┼─────────────────────────────┤
-- │ Row vs Scalar   │ Non-Correlated Subquery     │
-- │ Row vs Row      │ Correlated Subquery         │
-- │ Row vs Group    │ Correlated Subquery         │
-- │ Group vs Scalar │ HAVING + Scalar Subquery    │
-- │ Group vs Group  │ CTE + WHERE                 │
-- └─────────────────┴─────────────────────────────┘

-- Row vs Scalar (fixed company average)
WHERE salary > (SELECT AVG(salary) FROM employees)

-- Row vs Row (manager comparison)
WHERE salary > (
  SELECT salary FROM employees
  WHERE emp_id = e1.manager_id
)

-- Row vs Group (dept average per row)
WHERE salary > (
  SELECT AVG(salary) FROM employees
  WHERE dept = e1.dept
)

-- Group vs Scalar (dept total vs company avg)
SELECT dept, SUM(salary)
FROM employees
GROUP BY dept
HAVING SUM(salary) > (SELECT AVG(salary) FROM employees)

-- Group vs Group (dept avg vs avg of dept avgs)
WITH dept_totals AS (
  SELECT dept, SUM(salary) AS total
  FROM employees
  GROUP BY dept
)
SELECT dept, total
FROM dept_totals
WHERE total > (SELECT AVG(total) FROM dept_totals)

-- =============================================
-- 9. ALL THREE TOGETHER — Real World Example
-- =============================================

-- Business Problem:
-- "Find employees earning more than both
--  their dept average AND company average
--  Show their salary, dept avg, company avg"

WITH dept_avg AS (
  -- CTE → Pre-calculate dept averages
  SELECT dept, AVG(salary) AS dept_average
  FROM employees
  GROUP BY dept
)
SELECT
  e.name,
  e.dept,
  e.salary,
  -- Scalar Subquery → company average (Row vs Scalar)
  (SELECT AVG(salary) FROM employees) AS company_avg,
  -- CTE value → dept average (Row vs Group)
  da.dept_average,
  -- Differences
  e.salary - (SELECT AVG(salary) FROM employees)
    AS diff_from_company,
  e.salary - da.dept_average
    AS diff_from_dept
FROM employees e
JOIN dept_avg da ON e.dept = da.dept
WHERE
  -- Correlated → dept average comparison
  e.salary > (
    SELECT AVG(salary) FROM employees e2
    WHERE e2.dept = e.dept
  )
  AND
  -- Scalar → company average comparison
  e.salary > (SELECT AVG(salary) FROM employees);

-- =============================================
-- 10. CLASSIC INTERVIEW PROBLEMS
-- =============================================

-- PROBLEM 1: 2nd Highest Salary

-- Method 1: Subquery ✅
SELECT MAX(salary) FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Method 2: DENSE_RANK (Best for Nth!) ✅
WITH ranked AS (
  SELECT
    salary,
    DENSE_RANK() OVER(ORDER BY salary DESC) AS rnk
    -- No PARTITION BY → overall ranking!
    -- PARTITION BY → group wise ranking!
  FROM employees
)
SELECT DISTINCT salary
FROM ranked
WHERE rnk = 2;

-- Method 3: LIMIT OFFSET ✅
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 1;
-- OFFSET 1 → skip first row
-- LIMIT 1  → take next one

-- PROBLEM 2: Nth Highest Salary (Generic)
-- Just change WHERE rnk = N
WITH ranked AS (
  SELECT
    salary,
    DENSE_RANK() OVER(ORDER BY salary DESC) AS rnk
  FROM employees
)
SELECT DISTINCT salary
FROM ranked
WHERE rnk = 3; -- Change N here!

-- Why DENSE_RANK not RANK?
-- Salaries: 95000, 90000, 90000, 85000
-- RANK():       1,     2,     2,     4 ← gap! 3rd missing!
-- DENSE_RANK(): 1,     2,     2,     3 ← no gap! ✅

-- PROBLEM 3: Employees > Dept Average
SELECT name, dept, salary
FROM employees e1
WHERE salary > (
  SELECT AVG(salary)
  FROM employees e2
  WHERE e2.dept = e1.dept  -- correlated!
);

-- PROBLEM 4: Departments where avg > company avg
WITH dept_avg AS (
  SELECT dept, AVG(salary) AS dept_average
  FROM employees
  GROUP BY dept
)
SELECT dept, dept_average
FROM dept_avg
WHERE dept_average > (
  SELECT AVG(salary) FROM employees
);

-- PROBLEM 5: Employees earning more than ALL HR employees
-- Method 1: ALL keyword
SELECT name, dept, salary
FROM employees
WHERE salary > ALL (
  SELECT salary FROM employees
  WHERE dept = 'HR'
);

-- Method 2: MAX (same result, more readable!)
SELECT name, dept, salary
FROM employees
WHERE salary > (
  SELECT MAX(salary)
  FROM employees
  WHERE dept = 'HR'
);

-- =============================================
-- KEY RULES TO REMEMBER
-- =============================================

-- RULE 1: Single column in WHERE/SELECT subquery
-- ✅ WHERE salary > (SELECT AVG(salary)...)
-- ❌ WHERE salary > (SELECT dept, AVG(salary)...)

-- RULE 2: FROM subquery needs alias
-- ✅ FROM (...) AS dept_summary
-- ❌ FROM (...)

-- RULE 3: NOT EXISTS > NOT IN
-- NOT IN breaks with NULLs silently!
-- NOT EXISTS always safe!

-- RULE 4: PARTITION BY usage
-- Group wise ranking  → PARTITION BY dept ✅
-- Overall ranking     → No PARTITION BY ✅

-- RULE 5: Correlated = N executions
-- 10 rows → 10 executions
-- 1M rows → 1M executions → use CTE instead!

-- RULE 6: CTE can reference itself
-- Multiple CTEs → single WITH, comma separated!
-- WITH cte1 AS (...), cte2 AS (...) SELECT...
