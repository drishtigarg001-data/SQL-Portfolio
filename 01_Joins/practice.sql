-- =============================================
-- JOINS — PRACTICE QUESTIONS
-- =============================================
-- Format: Dataset → Trap → Question → Hint
-- Solutions: See solutions.sql
-- =============================================

-- =============================================
-- Q1: LEFT JOIN ON vs WHERE condition
-- =============================================

-- Dataset:
-- employees table
-- emp_id | name    | dept_id | salary
-- -------|---------|---------|-------
-- 1      | Alice   | 1       | 80000
-- 2      | Bob     | 1       | 60000
-- 3      | Charlie | 2       | 90000
-- 4      | David   | NULL    | 50000  ← no dept!
-- 5      | Eve     | 2       | 70000

-- departments table
-- id | dept_name
-- ---|----------
-- 1  | Tech
-- 2  | HR
-- 3  | Finance    ← no employees!

-- TRAP: Filter in ON vs WHERE behaves differently!

-- Q1a. What is the difference between these two?
-- Query A:
-- SELECT e.name, d.dept_name
-- FROM employees e
-- LEFT JOIN departments d
--   ON e.dept_id = d.id
--   AND d.dept_name = 'Tech';

-- Query B:
-- SELECT e.name, d.dept_name
-- FROM employees e
-- LEFT JOIN departments d
--   ON e.dept_id = d.id
-- WHERE d.dept_name = 'Tech';

-- Q1b. How many rows does each query return?
-- Hint: LEFT JOIN + WHERE = silent INNER JOIN!

-- Q1c. What happens to David (NULL dept_id)
--   in both queries?
-- Hint: NULL JOIN = no match!

-- Q1d. When should filter go in ON vs WHERE?
-- Hint: Right table filter → ON!
--       Result filter → WHERE!

-- =============================================
-- Q2: Finding Missing Records
-- =============================================

-- Dataset:
-- customers table
-- customer_id | name    | city
-- ------------|---------|--------
-- 1           | Alice   | Delhi
-- 2           | Bob     | Mumbai
-- 3           | Charlie | Delhi
-- 4           | David   | Pune
-- 5           | Eve     | Mumbai

-- orders table
-- order_id | customer_id | amount
-- ---------|-------------|-------
-- 101      | 1           | 500
-- 102      | 1           | 300
-- 103      | 2           | 700
-- 104      | 3           | 400
-- 105      | NULL        | 200   ← NULL customer!

-- TRAP: NOT IN breaks with NULLs!

-- Q2a. Find customers who NEVER placed an order
--   Using NOT EXISTS
--   Using LEFT JOIN + NULL
--   Using NOT IN
-- Hint: Which one breaks? Why?

-- Q2b. What happens when NULL is in orders table?
-- NOT IN (1, 2, 3, NULL) → what result?
-- Hint: NULL comparison = UNKNOWN!

-- Q2c. Which approach is safest? Why?
-- Hint: NOT EXISTS → NULL safe!

-- =============================================
-- Q3: Duplicate Explosion
-- =============================================

-- Dataset:
-- customers table
-- customer_id | name
-- ------------|------
-- 1           | Alice
-- 2           | Bob

-- orders table
-- order_id | customer_id | amount
-- ---------|-------------|-------
-- 101      | 1           | 500
-- 102      | 1           | 300
-- 103      | 1           | 700
-- 104      | 2           | 200

-- payments table
-- payment_id | customer_id | amount
-- -----------|-------------|-------
-- P1         | 1           | 400
-- P2         | 1           | 600
-- P3         | 2           | 200

-- TRAP: Two one-to-many JOINs = explosion!

-- Q3a. What is wrong with this query?
-- SELECT c.name,
--   SUM(o.amount) AS total_orders,
--   SUM(p.amount) AS total_payments
-- FROM customers c
-- LEFT JOIN orders o ON c.customer_id = o.customer_id
-- LEFT JOIN payments p ON c.customer_id = p.customer_id
-- GROUP BY c.name;
-- Hint: Trace Alice's rows after JOIN!

-- Q3b. What is the correct output?
-- Alice → total_orders = ?, total_payments = ?
-- Hint: 3 orders × 2 payments = 6 rows!

-- Q3c. Fix the query using pre-aggregation
-- Hint: CTE → aggregate first → then join!

-- =============================================
-- Q4: Self JOIN — Manager Hierarchy
-- =============================================

-- Dataset:
-- employees table
-- emp_id | name    | salary | manager_id
-- -------|---------|--------|------------
-- 1      | Alice   | 90000  | NULL  ← CEO
-- 2      | Bob     | 75000  | 1
-- 3      | Charlie | 60000  | 1
-- 4      | David   | 55000  | 2
-- 5      | Eve     | 50000  | 2
-- 6      | Frank   | 45000  | 3

-- Q4a. Write query: each employee with manager name
-- Hint: LEFT JOIN → keeps CEO (NULL manager)!

-- Q4b. Write query: employees earning MORE than manager
-- Hint: INNER JOIN intentional here!
--       No manager = can't compare = exclude!

-- Q4c. What happens to Alice (CEO) in both queries?
-- Hint: NULL manager_id → no match in self join!

-- Q4d. What is a self join in one sentence?
-- Hint: Table joins itself with two aliases!

-- =============================================
-- Q5: SEMI JOIN & ANTI JOIN
-- =============================================

-- Dataset:
-- products table
-- product_id | product_name | category
-- -----------|--------------|----------
-- P1         | Laptop       | Electronics
-- P2         | Phone        | Electronics
-- P3         | Desk         | Furniture
-- P4         | Chair        | Furniture
-- P5         | Tablet       | Electronics

-- order_items table
-- order_id | product_id | quantity
-- ---------|------------|----------
-- 101      | P1         | 2
-- 102      | P1         | 1
-- 103      | P2         | 3
-- 104      | P3         | 1
-- 105      | NULL       | 2   ← NULL product!

-- TRAP: NOT IN + NULL = zero rows!

-- Q5a. Write SEMI JOIN: products that HAVE been ordered
--   Using EXISTS
--   Using IN
-- Hint: Both are SEMI JOINs!

-- Q5b. Write ANTI JOIN: products NEVER ordered
--   Using NOT EXISTS
--   Using LEFT JOIN + NULL
-- Hint: NOT EXISTS → NULL safe!

-- Q5c. What does NOT IN return with NULL in subquery?
-- WHERE product_id NOT IN (P1, P2, P3, NULL)
-- Hint: NULL → UNKNOWN → zero rows!

-- Q5d. How many rows does each query return?
-- Trace through data carefully!

-- =============================================
-- Q6: JOIN with Date Conditions
-- =============================================

-- Dataset:
-- customers table
-- customer_id | name    | joined_date
-- ------------|---------|------------
-- 1           | Alice   | 2023-01-15
-- 2           | Bob     | 2023-03-20
-- 3           | Charlie | 2023-06-10
-- 4           | David   | 2024-01-05

-- orders table
-- order_id | customer_id | order_date  | amount
-- ---------|-------------|-------------|-------
-- 101      | 1           | 2023-02-10  | 500
-- 102      | 1           | 2023-08-15  | 300
-- 103      | 2           | 2023-04-01  | 700
-- 104      | 2           | 2023-04-30  | 200
-- 105      | 3           | 2023-07-20  | 400
-- 106      | 4           | 2024-02-01  | 600

-- TRAP: BETWEEN misses time component!

-- Q6a. Find orders placed within 90 days of joining
-- Hint: order_date >= joined_date
--       AND order_date <= DATE_ADD(joined_date, 90 days)

-- Q6b. Find customers with NO orders in first 90 days
-- Hint: Date condition in ON not WHERE!
--       LEFT JOIN + IS NULL!

-- Q6c. What is wrong with this?
-- WHERE order_date BETWEEN '2023-01-01' AND '2023-03-31'
-- Hint: Misses 2023-03-31 23:59:59!

-- Q6d. Safe date filter pattern?
-- Hint: >= start AND < next_day!

-- =============================================
-- Q7: COUNT(DISTINCT) After JOIN
-- =============================================

-- Dataset:
-- customers table
-- customer_id | name  | city
-- ------------|-------|--------
-- 1           | Alice | Delhi
-- 2           | Bob   | Mumbai
-- 3           | David | Delhi

-- orders table
-- order_id | customer_id | amount
-- ---------|-------------|-------
-- 1        | 1           | 500
-- 2        | 1           | 300   ← Alice has 2 orders
-- 3        | 1           | 700   ← Alice has 3 orders
-- 4        | 2           | 400
-- 5        | 3           | NULL  ← NULL amount

-- TRAP: COUNT(*) after JOIN = row count not customers!

-- Q7a. What is wrong with this?
-- SELECT city, COUNT(*) AS total_customers
-- FROM customers c
-- LEFT JOIN orders o ON c.customer_id = o.customer_id
-- GROUP BY city;
-- Hint: Alice has 3 orders → appears 3 times!

-- Q7b. Fix the query correctly
-- Hint: COUNT(DISTINCT customer_id)!

-- Q7c. Write query per city:
--   total customers, total orders, total revenue
-- Hint: COALESCE for NULL amounts!

-- Q7d. What is the difference between:
--   COUNT(c.customer_id) vs COUNT(DISTINCT c.customer_id)
--   after LEFT JOIN?

-- =============================================
-- Q8: SEMI JOIN vs ANTI JOIN vs CROSS JOIN
-- =============================================

-- Dataset:
-- sizes table          colors table
-- size_id | size_name  color_id | color_name
-- --------|--------    ---------|----------
-- 1       | Small      1        | Red
-- 2       | Medium     2        | Blue
-- 3       | Large      3        | Green

-- Q8a. Write query to generate ALL size+color combinations
-- Hint: CROSS JOIN!
-- How many rows? 3 × 3 = ?

-- Q8b. What is accidental CROSS JOIN?
-- SELECT * FROM sizes, colors;
-- What is wrong here?
-- Hint: Missing JOIN condition!

-- Q8c. When would you intentionally use CROSS JOIN?
-- Hint: Date spine, product variants!

-- =============================================
-- Q9: FULL OUTER JOIN
-- =============================================

-- Dataset:
-- system_a table        system_b table
-- txn_id | amount       txn_id | amount
-- -------|-------       -------|-------
-- 1      | 500          1      | 500
-- 2      | 300          3      | 400   ← only in B
-- 4      | 700          4      | 700
--                       5      | 200   ← only in B
-- 3 missing from A!

-- Q9a. Write FULL OUTER JOIN to show all transactions
--   from both systems
-- Hint: NULL where no match!

-- Q9b. Write query to find:
--   Transactions only in System A
--   Transactions only in System B
--   Matched transactions
-- Hint: CASE WHEN with IS NULL!

-- Q9c. MySQL does not support FULL OUTER JOIN
--   How do you simulate it?
-- Hint: LEFT JOIN UNION RIGHT JOIN!
