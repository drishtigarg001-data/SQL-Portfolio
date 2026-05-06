-- =============================================
-- SUBQUERIES & CTEs — PRACTICE QUESTIONS
-- =============================================
-- Format: Dataset → Trap → Question → Hint
-- Solutions: See solutions.sql
-- =============================================

-- =============================================
-- TOPIC 1: SCALAR SUBQUERY
-- =============================================

-- Dataset:
-- employees table
-- emp_id | name    | dept    | salary | join_year
-- -------|---------|---------|--------|----------
-- 1      | Alice   | Tech    | 80000  | 2019
-- 2      | Bob     | Tech    | 60000  | 2020
-- 3      | Charlie | Tech    | 90000  | 2018
-- 4      | David   | HR      | 50000  | 2021
-- 5      | Eve     | HR      | 70000  | 2019
-- 6      | Frank   | Finance | 85000  | 2020
-- 7      | Grace   | Finance | 95000  | 2018
-- 8      | Henry   | Finance | 75000  | 2021
-- 9      | Ivan    | Tech    | NULL   | 2022
-- 10     | Julia   | HR      | 55000  | 2020

-- Q1. Show each employee with:
--   their salary, company average, difference from avg
-- Hint: Scalar subquery in SELECT!
--       Runs ONCE → same value for every row!

-- Q2. Find employees earning more than company average
--   Once using subquery in WHERE
--   Once using CTE
-- Hint: CTE → WITH avg AS (SELECT AVG...)

-- Q3. What is difference between:
-- Query A: WHERE salary > (SELECT AVG(salary) FROM employees)
-- Query B: WHERE salary > (SELECT AVG(salary) FROM employees
--                          WHERE dept = 'Tech')
-- Hint: Fixed value vs dept specific value!

-- Q4. What happens to Ivan (NULL salary)?
-- Hint: NULL > any_value = UNKNOWN → excluded!

-- =============================================
-- TOPIC 2: CORRELATED SUBQUERY
-- =============================================

-- Dataset: Same employees table above

-- TRAP: Correlated subquery runs N times!

-- Q1. Find employees earning more than dept average
-- Hint: WHERE salary > (SELECT AVG(salary)
--         FROM employees e2 WHERE e2.dept = e1.dept)

-- Q2. Find employees earning more than their manager
-- Hint: e1 = current employee, e2 = manager
--       WHERE e2.emp_id = e1.manager_id!

-- Q3. What is difference between:
-- Non-Correlated: WHERE salary > (SELECT AVG(salary) FROM employees)
-- Correlated: WHERE salary > (SELECT AVG(salary) FROM employees e2
--                              WHERE e2.dept = e1.dept)
-- Hint: How many times does inner query run?

-- Q4. Performance problem with correlated subquery?
--   When would you still use it?
-- Hint: N rows = N executions!

-- =============================================
-- TOPIC 3: SUBQUERY PLACEMENT
-- =============================================

-- Dataset:
-- orders table
-- order_id | customer_id | amount | status    | order_date
-- ---------|-------------|--------|-----------|------------
-- 1        | C1          | 500    | completed | 2023-01-10
-- 2        | C1          | 300    | cancelled | 2023-02-15
-- 3        | C2          | 700    | completed | 2023-01-20
-- 4        | C2          | 400    | completed | 2023-03-10
-- 5        | C3          | 600    | completed | 2023-02-05
-- 6        | C3          | 200    | cancelled | 2023-03-15
-- 7        | C4          | 800    | completed | 2023-01-25
-- 8        | C5          | 350    | completed | 2023-02-20

-- TRAP: WHERE subquery → single column only!

-- Q1. Using subquery in WHERE:
--   Find orders where amount > average order amount
-- Hint: Single value comparison!

-- Q2. Using subquery in FROM:
--   Find customers whose total spending > average customer spending
-- Hint: Derived table → alias REQUIRED!

-- Q3. Using subquery in SELECT:
--   Show each order with amount, overall avg, difference
-- Hint: Scalar subquery → runs once!

-- Q4. What is wrong with this?
-- SELECT customer_id, amount, SUM(amount) AS total
-- FROM orders
-- WHERE total > 1000
-- GROUP BY customer_id;
-- Hint: SQL execution order!

-- Q5. Rewrite Q4 correctly — 3 ways:
--   Using subquery in FROM
--   Using HAVING
--   Using CTE
-- Hint: HAVING → after GROUP BY → aggregates allowed!

-- =============================================
-- TOPIC 4: EXISTS vs IN
-- =============================================

-- Dataset:
-- customers (customer_id, name, city)
-- orders (order_id, customer_id, amount, status)
-- orders has one row with NULL customer_id!

-- TRAP: NOT IN + NULL = ZERO rows!

-- Q1. Find customers who HAVE placed orders:
--   Using IN
--   Using EXISTS
-- Hint: EXISTS short circuits → faster!

-- Q2. Find customers who NEVER placed orders:
--   Using NOT IN
--   Using NOT EXISTS
--   Using LEFT JOIN + NULL
-- Hint: Which one breaks with NULL?

-- Q3. What happens when NULL in subquery?
-- WHERE customer_id NOT IN (1, 2, 3, NULL)
-- Hint: NULL comparison = UNKNOWN!
--       UNKNOWN → zero rows!

-- Q4. Which is faster — EXISTS or IN? Why?
-- Hint: Short circuit vs full scan!

-- =============================================
-- TOPIC 5: CLASSIC PROBLEMS
-- =============================================

-- Dataset: Same employees table

-- Q1. Find 2nd highest salary — 3 ways:
--   Using subquery
--   Using LIMIT/OFFSET
--   Using DENSE_RANK window function
-- Hint: DENSE_RANK → no gaps with ties!

-- Q2. Find employees earning more than dept average
-- Hint: Correlated subquery!

-- Q3. Find Nth highest salary (generic — N=3)
-- Hint: DENSE_RANK() OVER(ORDER BY salary DESC)

-- Q4. Find departments where avg salary > company avg
-- Hint: CTE for dept averages, scalar for company avg!

-- Q5. Find employees earning more than ALL HR employees
-- Hint: ALL keyword or MAX!

-- =============================================
-- TOPIC 6: CTE vs SUBQUERY vs DERIVED TABLE
-- =============================================

-- Dataset: Same sales table

-- Q1. Write same query 3 ways:
--   Per region total sales > 30000
--   Using Derived Table
--   Using CTE
--   Using Subquery in WHERE
-- Hint: Derived table needs alias!

-- Q2. When to use CTE vs Subquery?
-- Give 3 real examples of each!

-- Q3. Can CTE reference itself?
--   What is that called?
-- Hint: Recursive CTE!

-- Q4. What is wrong with this?
-- WITH sales_summary AS (SELECT region, SUM(amount) AS total
--                        FROM sales GROUP BY region),
-- WITH region_filter AS (SELECT region FROM sales_summary
--                        WHERE total > 30000)
-- SELECT * FROM region_filter;
-- Hint: Double WITH!

-- Q5. Rewrite using 2 chained CTEs
-- Hint: One WITH, comma separated!

-- =============================================
-- TOPIC 7: MULTIPLE CTEs CHAINING
-- =============================================

-- Dataset: Same employees table

-- Q1. Write query using 3 chained CTEs:
--   Step 1: Department averages
--   Step 2: Company average (single value)
--   Step 3: Employees above BOTH averages
--   Final: name, dept, salary, dept_avg, company_avg, label
-- Hint: CROSS JOIN for single row CTE!

-- Q2. What is execution order of multiple CTEs?
-- WITH cte1 AS (...), cte2 AS (...), cte3 AS (...)
-- Hint: Top to bottom!

-- Q3. Can cte2 reference cte1? Can cte1 reference cte2?
-- Hint: Forward reference only!

-- Q4. What is wrong with this?
-- WITH dept_summary AS (SELECT dept, AVG(salary) AS avg_sal,
--                       FROM employees GROUP BY dept),
-- WITH top_earners AS (SELECT * FROM dept_summary
--                      WHERE avg_sal > 70000)
-- SELECT * FROM top_earners;
-- Hint: Two problems — find both!

-- =============================================
-- TOPIC 8: SUBQUERY vs JOIN PERFORMANCE
-- =============================================

-- Dataset:
-- customers (customer_id, name, city, segment)
-- orders (order_id, customer_id, amount, status)

-- Q1. Write query two ways:
--   Customers with at least one completed order
--   Using EXISTS
--   Using JOIN
-- Hint: JOIN needs DISTINCT! EXISTS does not!

-- Q2. Which is faster — EXISTS or JOIN? Why?
--   When does JOIN become problematic?
-- Hint: Short circuit vs duplicate explosion!

-- Q3. Customers with total orders > 500:
--   Using Correlated Subquery
--   Using JOIN + GROUP BY
--   Which is better and why?
-- Hint: N executions vs one scan!

-- Q4. "Subquery is always slower than JOIN" — correct?
--   When is subquery actually better?
-- Hint: EXISTS vs JOIN + DISTINCT!

-- =============================================
-- TOPIC 9: CTE READABILITY vs PERFORMANCE
-- =============================================

-- Q1. Write same logic two ways:
--   Reps whose Electronics sales > total average
--   Using nested subqueries
--   Using CTEs
-- Hint: CTE much more readable!

-- Q2. What is CTE materialization?
--   Does PostgreSQL always materialize?
-- Hint: PostgreSQL 12+ → auto inline!

-- Q3. Performance difference between CTE and Subquery?
-- WITH summary AS (...) SELECT * FROM summary WHERE...
-- vs
-- SELECT * FROM (...) AS summary WHERE...
-- Hint: Modern PostgreSQL → same execution plan!

-- Q4. When CTE, when Subquery — 3 examples each?

-- =============================================
-- TOPIC 10: RECURSIVE CTE
-- =============================================

-- Dataset:
-- employees table with manager_id column
-- emp_id | name | dept | salary | manager_id
-- Alice (1) = CEO, manager_id = NULL

-- Q1. Write Recursive CTE for org hierarchy:
--   emp_id, name, manager_id, level
--   Level 1 = CEO, Level 2 = direct reports
-- Hint: Anchor = WHERE manager_id IS NULL
--       Recursive = JOIN on manager_id = emp_id

-- Q2. Two parts of Recursive CTE?
--   Explain with example from Q1
-- Hint: Anchor Member + Recursive Member!

-- Q3. Infinite loop risk — how to prevent?
-- Hint: WHERE level < N in recursive member!

-- Q4. Find ALL subordinates of Bob (emp_id=2)
--   Direct AND indirect!
-- Hint: Start from Bob, recurse through reports!

-- =============================================
-- TOPIC 11: CTE MATERIALIZATION
-- =============================================

-- Q1. What is CTE materialization?
--   When is it good vs bad?

-- Q2. How to force materialization in PostgreSQL?
-- Hint: MATERIALIZED keyword!

-- Q3. When would you use MATERIALIZED?
-- Hint: Same CTE referenced multiple times!

-- =============================================
-- TOPIC 12: CTE vs TEMP TABLE vs VIEW
-- =============================================

-- Q1. Which would you use for ETL pipeline
--   where same result needed in 5 queries?
-- Hint: Temp Table → indexable, session-wide!

-- Q2. Business team needs simple interface
--   for complex joins — they don't write SQL.
--   What do you use?
-- Hint: View → permanent, reusable!

-- Q3. Difference between View and Materialized View?
-- Hint: Virtual vs physical data!
--       Fresh vs snapshot!
--       REFRESH needed!

-- Q4. "Always use Temp Tables instead of CTEs"
--   Is this correct? When would you disagree?
-- Hint: CTE better for single query, recursive!

-- =============================================
-- TOPIC 13: PERFORMANCE IMPLICATIONS
-- =============================================

-- Q1. What are 5 key performance rules
--   for subqueries and CTEs?
-- Hint: Filter early, EXISTS > IN,
--       Avoid correlated on large data,
--       Avoid SELECT *, avoid functions on indexed cols!

-- Q2. How would you replace this slow query?
-- SELECT name FROM employees e1
-- WHERE salary > (SELECT AVG(salary) FROM employees e2
--                 WHERE e2.dept = e1.dept)
-- Hint: Replace correlated with CTE + JOIN!

-- Q3. What is wrong with this date filter?
-- WHERE EXTRACT(YEAR FROM order_date) = 2023
-- Hint: Function on indexed column = index not used!

-- Q4. Senior level answer:
--   "How do you optimize slow SQL queries?"
-- Hint: Filter early, right joins, indexes,
--       explain analyze, avoid functions on cols!
