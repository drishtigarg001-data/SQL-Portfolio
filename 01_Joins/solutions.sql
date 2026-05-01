-- =============================================
-- JOINS — SOLUTIONS
-- =============================================
-- Format: Question → Solution + Key Points
-- =============================================

-- =============================================
-- Q1: LEFT JOIN ON vs WHERE
-- =============================================

-- Q1a & Q1b Solution:

-- Query A — Filter in ON (10 rows):
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.id
  AND d.dept_name = 'Tech';
-- Result:
-- Alice   | Tech    ← match!
-- Bob     | Tech    ← match!
-- Charlie | NULL    ← kept, no Tech match
-- David   | NULL    ← kept, NULL dept_id
-- Eve     | NULL    ← kept, no Tech match
-- ALL 5 rows returned!

-- Query B — Filter in WHERE (2 rows):
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.id
WHERE d.dept_name = 'Tech';
-- Result:
-- Alice | Tech
-- Bob   | Tech
-- Only 2 rows! NULL rows filtered out!
-- Silently became INNER JOIN!

-- Q1c. David (NULL dept_id):
-- Query A → David kept with NULL dept_name ✅
-- Query B → David filtered out by WHERE ❌

-- Q1d. Rule:
-- Right table filter → ON condition ✅
-- Result filter      → WHERE condition ✅
-- WHERE on right table after LEFT JOIN
-- = silent INNER JOIN!

-- KEY POINTS:
-- ON filters during JOIN → preserves LEFT JOIN
-- WHERE filters after JOIN → removes NULLs
-- Always put right table filters in ON!

-- =============================================
-- Q2: Finding Missing Records
-- =============================================

-- Q2a. Three approaches:

-- NOT EXISTS ✅ (safest!)
SELECT c.customer_id, c.name
FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
);

-- LEFT JOIN + NULL ✅
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- NOT IN ⚠️ DANGEROUS!
SELECT customer_id, name
FROM customers
WHERE customer_id NOT IN (
  SELECT customer_id FROM orders
  -- NULL here → returns ZERO rows!
);

-- Q2b. NULL trap:
-- orders has NULL customer_id
-- NOT IN (1, 2, 3, NULL) expands to:
-- customer_id != 1
-- AND customer_id != 2
-- AND customer_id != 3
-- AND customer_id != NULL ← UNKNOWN!
-- UNKNOWN → entire WHERE = UNKNOWN
-- Result = ZERO rows! Silent bug! 😱

-- Q2c. Safest: NOT EXISTS
-- Checks existence row by row
-- NULL in subquery → no match for any customer
-- David correctly returned! ✅

-- KEY POINTS:
-- NOT EXISTS → always NULL safe! ✅
-- LEFT JOIN + NULL → NULL safe! ✅
-- NOT IN → breaks with NULLs! ⚠️
-- Always prefer NOT EXISTS over NOT IN!

-- =============================================
-- Q3: Duplicate Explosion
-- =============================================

-- Q3a. Wrong query explanation:
-- Alice has 3 orders + 2 payments
-- JOIN creates 3×2 = 6 rows for Alice!
-- SUM(orders) = 500+500+300+300+700+700 = 3000 ❌
-- SUM(payments) = 400+600+400+600+400+600 = 3000 ❌
-- Both WRONG! Should be 1500 and 1000!

-- Q3b. Correct output:
-- Alice → total_orders = 1500, total_payments = 1000
-- Bob   → total_orders = 200,  total_payments = 200

-- Q3c. Fixed query — pre-aggregate first!
WITH order_totals AS (
  SELECT customer_id, SUM(amount) AS total_orders
  FROM orders GROUP BY customer_id
),
payment_totals AS (
  SELECT customer_id, SUM(amount) AS total_payments
  FROM payments GROUP BY customer_id
)
SELECT
  c.name,
  COALESCE(ot.total_orders, 0) AS total_orders,
  COALESCE(pt.total_payments, 0) AS total_payments
FROM customers c
LEFT JOIN order_totals ot ON c.customer_id = ot.customer_id
LEFT JOIN payment_totals pt ON c.customer_id = pt.customer_id;

-- KEY POINTS:
-- Two one-to-many tables → pre-aggregate!
-- Raw JOIN → cartesian explosion!
-- CTE → pre-aggregate → join 1-to-1!
-- COALESCE → handle NULL for customers
--            with no orders/payments!

-- =============================================
-- Q4: Self JOIN — Manager Hierarchy
-- =============================================

-- Q4a. Each employee with manager:
SELECT
  e.name AS employee,
  m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;
-- LEFT JOIN → Alice (CEO) kept with NULL manager! ✅
-- Result:
-- Alice  | NULL    ← CEO, no manager
-- Bob    | Alice
-- Charlie| Alice
-- David  | Bob
-- Eve    | Bob
-- Frank  | Charlie

-- Q4b. Employees earning more than manager:
SELECT
  e.name AS employee,
  m.name AS manager,
  e.salary AS emp_salary,
  m.salary AS mgr_salary
FROM employees e
JOIN employees m ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;
-- INNER JOIN intentional!
-- Alice (CEO) → no manager → excluded ✅
-- Nobody earns more than manager here
-- Result = 0 rows (correct, not a bug!)

-- Q4c. Alice (CEO) behavior:
-- Q4a → Alice returned with NULL manager ✅
-- Q4b → Alice excluded (no manager to compare) ✅

-- Q4d. Self JOIN definition:
-- A table joining itself using two aliases
-- to compare rows within the same table
-- Used for hierarchical data like
-- employee-manager relationships!

-- KEY POINTS:
-- Self JOIN → alias table twice (e, m)!
-- LEFT JOIN → keep root level (CEO)!
-- INNER JOIN → only when both sides must exist!
-- manager_id = emp_id → find the manager!

-- =============================================
-- Q5: SEMI JOIN & ANTI JOIN
-- =============================================

-- Q5a. SEMI JOIN — products ordered:

-- Using EXISTS ✅ (preferred!)
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

-- Q5b. ANTI JOIN — products never ordered:

-- NOT EXISTS ✅ (safest!)
SELECT p.product_id, p.product_name
FROM products p
WHERE NOT EXISTS (
  SELECT 1 FROM order_items oi
  WHERE oi.product_id = p.product_id
);

-- LEFT JOIN + NULL ✅
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi
  ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- Q5c. NOT IN with NULL:
-- order_items has NULL product_id
-- NOT IN (P1, P2, P3, NULL)
-- product_id != NULL = UNKNOWN
-- Result = ZERO rows! Complete failure! 😱

-- Q5d. Row counts:
-- SEMI JOIN (ordered): P1, P2, P3 = 3 rows
-- ANTI JOIN (never ordered): P4, P5 = 2 rows
-- NOT IN result: 0 rows! (NULL trap!)

-- KEY POINTS:
-- SEMI JOIN → EXISTS/IN → no duplicates!
-- ANTI JOIN → NOT EXISTS → NULL safe!
-- NOT IN → zero rows with NULL in subquery!
-- EXISTS short circuits → faster on large data!

-- =============================================
-- Q6: JOIN with Date Conditions
-- =============================================

-- Q6a. Orders within 90 days of joining:
SELECT
  c.name,
  c.joined_date,
  o.order_date,
  o.amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= c.joined_date
AND o.order_date <= DATE_ADD(c.joined_date, INTERVAL 90 DAY);
-- Alice joined 2023-01-15 → window ends 2023-04-15
-- Order 101: 2023-02-10 ✅ within 90 days
-- Order 102: 2023-08-15 ❌ too late!

-- Q6b. Customers with NO orders in first 90 days:
SELECT c.name
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
  AND o.order_date >= c.joined_date
  AND o.order_date <= DATE_ADD(c.joined_date, INTERVAL 90 DAY)
WHERE o.order_id IS NULL;
-- Date condition in ON → preserves LEFT JOIN!
-- Date condition in WHERE → silent INNER JOIN!

-- Q6c. BETWEEN pitfall:
-- BETWEEN '2023-01-01' AND '2023-03-31'
-- Misses: 2023-03-31 23:59:59! ❌
-- Different databases behave differently!

-- Q6d. Safe date filter:
WHERE order_date >= '2023-01-01'
AND order_date < '2023-04-01'  -- first day of next month!
-- 2023-03-31 23:59:59 safely included! ✅

-- KEY POINTS:
-- BETWEEN → never use for datetime! ⚠️
-- Use >= start AND < next_day instead!
-- Date condition on right table → in ON!
-- DATE_ADD → platform specific syntax!

-- =============================================
-- Q7: COUNT(DISTINCT) After JOIN
-- =============================================

-- Q7a. Wrong query explanation:
-- Alice has 3 orders → appears 3 times after JOIN!
-- COUNT(*) per city:
-- Delhi → Alice(3) + David(1) = 4 ❌ (should be 2!)
-- Mumbai → Bob(1) = 1 ✅

-- Q7b. Fixed query:
SELECT c.city,
  COUNT(DISTINCT c.customer_id) AS total_customers
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city;
-- Alice counted ONCE despite 3 orders! ✅

-- Q7c. Complete per city query:
SELECT
  c.city,
  COUNT(DISTINCT c.customer_id) AS total_customers,
  COUNT(o.order_id) AS total_orders,
  COALESCE(SUM(o.amount), 0) AS total_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city;

-- Q7d. COUNT difference:
-- COUNT(c.customer_id) → counts rows
--   Alice 3 orders → counted 3 times! ❌
-- COUNT(DISTINCT c.customer_id) → unique entities
--   Alice → counted once! ✅

-- KEY POINTS:
-- After JOIN → COUNT(DISTINCT parent_id) always!
-- COUNT(*) = row count not entity count!
-- COALESCE(SUM(), 0) → NULL amounts handled!
-- LEFT JOIN → all customers including no orders!

-- =============================================
-- Q8: CROSS JOIN
-- =============================================

-- Q8a. All size + color combinations:
SELECT s.size_name, c.color_name
FROM sizes s
CROSS JOIN colors c;
-- 3 sizes × 3 colors = 9 rows!
-- Small-Red, Small-Blue, Small-Green
-- Medium-Red, Medium-Blue, Medium-Green
-- Large-Red, Large-Blue, Large-Green

-- Q8b. Accidental CROSS JOIN:
SELECT * FROM sizes, colors;
-- Missing JOIN condition!
-- Every size × every color = 9 rows!
-- On large tables → millions of rows! 💀

-- Q8c. Intentional CROSS JOIN use cases:
-- 1. Product variants (size × color)
-- 2. Date spine generation
-- 3. Scenario analysis (discount × product)
-- 4. Single row CTE × main table
--    (company average to every row!)

-- KEY POINTS:
-- CROSS JOIN → cartesian product!
-- Always intentional! Never accidental!
-- Missing JOIN condition = accidental CROSS JOIN!
-- Single row CTE + CROSS JOIN = clean pattern!

-- =============================================
-- Q9: FULL OUTER JOIN
-- =============================================

-- Q9a. Show all transactions from both systems:
SELECT
  COALESCE(a.txn_id, b.txn_id) AS txn_id,
  a.amount AS system_a_amount,
  b.amount AS system_b_amount
FROM system_a a
FULL OUTER JOIN system_b b ON a.txn_id = b.txn_id;
-- Result:
-- 1 | 500 | 500  ← matched
-- 2 | 300 | NULL ← only in A
-- 3 | NULL| 400  ← only in B
-- 4 | 700 | 700  ← matched
-- 5 | NULL| 200  ← only in B

-- Q9b. Categorize transactions:
SELECT
  COALESCE(a.txn_id, b.txn_id) AS txn_id,
  CASE
    WHEN a.txn_id IS NULL THEN 'Only in System B'
    WHEN b.txn_id IS NULL THEN 'Only in System A'
    ELSE 'Matched'
  END AS status
FROM system_a a
FULL OUTER JOIN system_b b ON a.txn_id = b.txn_id;

-- Q9c. MySQL workaround:
SELECT a.txn_id, a.amount AS a_amt, b.amount AS b_amt
FROM system_a a
LEFT JOIN system_b b ON a.txn_id = b.txn_id

UNION

SELECT b.txn_id, a.amount AS a_amt, b.amount AS b_amt
FROM system_a a
RIGHT JOIN system_b b ON a.txn_id = b.txn_id;

-- KEY POINTS:
-- FULL OUTER JOIN → all rows from both sides!
-- NULL where no match on either side!
-- Use for reconciliation reports!
-- MySQL → LEFT JOIN UNION RIGHT JOIN!
-- COALESCE(a.id, b.id) → handle NULL ids!

-- =============================================
-- KEY TAKEAWAYS — JOINS
-- =============================================

-- 1. ON vs WHERE → right table filter in ON!
-- 2. NOT EXISTS > NOT IN → NULL safe!
-- 3. Pre-aggregate → two one-to-many tables!
-- 4. Self JOIN → alias twice (e, m)!
-- 5. COUNT(DISTINCT) → after JOIN always!
-- 6. BETWEEN → never for datetime!
-- 7. EXISTS → short circuits → faster!
-- 8. CROSS JOIN → always intentional!
-- 9. FULL OUTER → reconciliation reports!
-- 10. LEFT JOIN → all left + NULL for no match!
