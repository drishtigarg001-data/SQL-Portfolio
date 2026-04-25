-- =============================================
-- JOINS — PRACTICE QUESTIONS & ANSWERS
-- =============================================

-- =============================================
-- Q1: LEFT JOIN ON vs WHERE condition
-- =============================================

-- Tables:
-- employees (emp_id, name, dept_id)
-- departments (id, dept_name)

-- QUESTION:
-- What is the difference between these two queries?

-- Query A
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.id
  AND d.dept_name = 'Engineering';

-- Query B
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.id
WHERE d.dept_name = 'Engineering';

-- MY ANSWER:
-- Query A: Filter applied in ON condition
--          LEFT JOIN behavior preserved
--          All employees returned
--          Non-Engineering dept_name = NULL

-- Query B: Filter applied in WHERE
--          Silently becomes INNER JOIN!
--          Only Engineering employees returned
--          NULL rows filtered out by WHERE

-- CORRECT OUTPUT:
-- Query A → 10 rows (all employees)
-- Query B → 3 rows (only Engineering)

-- KEY LESSON:
-- WHERE on right table after LEFT JOIN
-- = silently converts to INNER JOIN!
-- Put filter in ON to preserve LEFT JOIN behavior

-- =============================================
-- Q2: Finding Missing Records
-- =============================================

-- Tables:
-- customers (customer_id, name)
-- orders (order_id, customer_id, amount)

-- QUESTION:
-- Find customers who have NEVER placed an order

-- MY ANSWER — NOT EXISTS:
SELECT c.customer_id, c.name
FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
);

-- MY ANSWER — LEFT JOIN + NULL:
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- WHY NOT IN IS DANGEROUS:
-- NOT IN (1, 2, NULL) → returns ZERO rows!
-- NULL comparison = UNKNOWN
-- UNKNOWN = entire WHERE fails silently!

-- KEY LESSON:
-- Always prefer NOT EXISTS over NOT IN
-- NOT EXISTS is NULL safe
-- NOT IN breaks silently with NULLs

-- =============================================
-- Q3: Duplicate Explosion & Pre-Aggregation
-- =============================================

-- Tables:
-- customers, orders, payments

-- QUESTION:
-- Get total orders + total payments per customer

-- WRONG WAY → Duplicate Explosion!
SELECT
  c.name,
  SUM(o.amount) AS total_orders,   -- WRONG! inflated!
  SUM(p.amount) AS total_payments  -- WRONG! inflated!
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN payments p ON c.customer_id = p.customer_id
GROUP BY c.name;

-- WHY WRONG:
-- Alice has 3 orders + 2 payments
-- JOIN creates 3x2 = 6 rows for Alice
-- SUM counts each amount multiple times!

-- CORRECT WAY → Pre-Aggregate First!
WITH order_totals AS (
  SELECT customer_id, SUM(amount) AS total_orders
  FROM orders
  GROUP BY customer_id
),
payment_totals AS (
  SELECT customer_id, SUM(amount) AS total_payments
  FROM payments
  GROUP BY customer_id
)
SELECT
  c.name,
  ot.total_orders,
  pt.total_payments
FROM customers c
LEFT JOIN order_totals ot ON c.customer_id = ot.customer_id
LEFT JOIN payment_totals pt ON c.customer_id = pt.customer_id;

-- KEY LESSON:
-- Two one-to-many tables joining same parent
-- → Always pre-aggregate each child table first!
-- → Join 1-to-1 rows → no explosion possible!

-- =============================================
-- Q4: Self JOIN — Manager Employee Hierarchy
-- =============================================

-- Table: employees (emp_id, name, salary, manager_id)

-- QUESTION 1: Show each employee with manager name
SELECT
  e.name AS employee,
  m.name AS manager
FROM employees e
LEFT JOIN employees m
  ON e.manager_id = m.emp_id;
-- LEFT JOIN → CEO (NULL manager_id) kept in result!
-- INNER JOIN → CEO would disappear!

-- QUESTION 2: Employees earning more than manager
SELECT
  e.name AS employee,
  m.name AS manager,
  e.salary AS emp_salary,
  m.salary AS mgr_salary
FROM employees e
JOIN employees m
  ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;
-- INNER JOIN intentional here!
-- No manager = can't compare = exclude!

-- KEY LESSON:
-- Self JOIN → alias table twice (e, m)
-- LEFT JOIN → keep root level (CEO)
-- INNER JOIN → only when both sides must exist

-- =============================================
-- Q5: SEMI JOIN & ANTI JOIN
-- =============================================

-- Table: products, order_items

-- SEMI JOIN → products that HAVE been ordered
-- Using EXISTS (preferred!)
SELECT p.product_id, p.product_name
FROM products p
WHERE EXISTS (
  SELECT 1 FROM order_items oi
  WHERE oi.product_id = p.product_id
);

-- Using IN
SELECT product_id, product_name
FROM products
WHERE product_id IN (
  SELECT product_id FROM order_items
);

-- ANTI JOIN → products NEVER ordered
-- Using NOT EXISTS ✅
SELECT p.product_id, p.product_name
FROM products p
WHERE NOT EXISTS (
  SELECT 1 FROM order_items oi
  WHERE oi.product_id = p.product_id
);

-- Using LEFT JOIN + NULL ✅
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi
  ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- KEY LESSON:
-- SEMI JOIN → EXISTS/IN → no duplicates!
-- ANTI JOIN → NOT EXISTS → NULL safe!
-- NOT IN → dangerous with NULLs!

-- =============================================
-- Q6: JOIN with Date Conditions
-- =============================================

-- QUESTION: Orders placed within 90 days of joining

SELECT
  c.name,
  c.joined_date,
  o.order_date,
  o.amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= c.joined_date
AND o.order_date <= DATE_ADD(c.joined_date, INTERVAL 90 DAY);

-- BETWEEN PITFALL:
-- BETWEEN '2023-01-01' AND '2023-03-31'
-- Misses: 2023-03-31 23:59:59!

-- SAFE WAY:
WHERE order_date >= '2023-01-01'
AND order_date < '2023-04-01'  -- next day!

-- KEY LESSON:
-- Never use BETWEEN for datetime columns
-- Use >= start AND < next_day instead!

-- =============================================
-- Q7: COUNT(DISTINCT) After JOIN
-- =============================================

-- WRONG → COUNT(*) counts rows not customers!
SELECT c.city,
  COUNT(*) AS total_customers  -- inflated!
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city;

-- CORRECT → COUNT(DISTINCT) deduplicates!
SELECT c.city,
  COUNT(DISTINCT c.customer_id) AS total_customers,
  COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city;

-- KEY LESSON:
-- After JOIN → always COUNT(DISTINCT parent_id)
-- COUNT(*) counts rows → inflated after one-to-many JOIN!
