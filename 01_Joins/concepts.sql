-- =============================================
-- JOINS — COMPLETE CONCEPTS
-- =============================================

-- =============================================
-- 1. TYPES OF JOINS
-- =============================================

-- INNER JOIN → only matching rows from both tables
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.id;

-- LEFT JOIN → all left rows + matching right
--             NULL where no match on right
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id;

-- RIGHT JOIN → all right rows + matching left
--              NULL where no match on left
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.id;

-- FULL OUTER JOIN → all rows from both sides
--                   NULL where no match either side
SELECT e.name, d.dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.id;

-- MySQL workaround for FULL OUTER JOIN:
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id
UNION
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.id;

-- CROSS JOIN → every row × every row (cartesian!)
SELECT p.product_name, c.color
FROM products p
CROSS JOIN colors c;
-- 5 products × 3 colors = 15 rows!
-- Use intentionally for combinations
-- Accidental CROSS JOIN = query crash!

-- SELF JOIN → table joins itself
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- =============================================
-- 2. ON vs WHERE — THE MOST IMPORTANT TRAP
-- =============================================

-- Filter in ON → preserves LEFT JOIN behavior
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.id
  AND d.dept_name = 'Engineering';
-- Returns ALL employees
-- Non-Engineering → dept_name = NULL

-- Filter in WHERE → silently becomes INNER JOIN!
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.id
WHERE d.dept_name = 'Engineering';
-- Returns ONLY Engineering employees
-- NULL rows filtered out by WHERE!

-- RULE:
-- Filter right table → put in ON
-- Filter result → put in WHERE

-- =============================================
-- 3. SEMI JOIN & ANTI JOIN
-- =============================================

-- SEMI JOIN → rows where match EXISTS
-- No duplicates! Only left table columns!

-- Using EXISTS ✅ (preferred!)
SELECT c.customer_id, c.name
FROM customers c
WHERE EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
);

-- Using IN
SELECT customer_id, name
FROM customers
WHERE customer_id IN (
  SELECT customer_id FROM orders
);

-- ANTI JOIN → rows where NO match exists

-- Using NOT EXISTS ✅ (safest!)
SELECT c.customer_id, c.name
FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
);

-- Using LEFT JOIN + NULL ✅
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- Using NOT IN ⚠️ DANGEROUS!
SELECT customer_id, name
FROM customers
WHERE customer_id NOT IN (
  SELECT customer_id FROM orders
  -- If ANY NULL here → returns ZERO rows!
);

-- =============================================
-- 4. DUPLICATE EXPLOSION & PRE-AGGREGATION
-- =============================================

-- PROBLEM: Two one-to-many tables on same parent
-- customers → orders (one-to-many)
-- customers → payments (one-to-many)

-- WRONG → Duplicate explosion!
SELECT
  c.name,
  SUM(o.amount) AS total_orders,   -- inflated!
  SUM(p.amount) AS total_payments  -- inflated!
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN payments p ON c.customer_id = p.customer_id
GROUP BY c.name;
-- Alice has 3 orders + 2 payments
-- JOIN creates 6 rows → SUM inflated!

-- CORRECT → Pre-aggregate first!
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
  ot.total_orders,
  pt.total_payments
FROM customers c
LEFT JOIN order_totals ot ON c.customer_id = ot.customer_id
LEFT JOIN payment_totals pt ON c.customer_id = pt.customer_id;

-- RULE:
-- Multiple one-to-many tables on same parent
-- → Pre-aggregate each child table first!
-- → Join 1-to-1 → no explosion!

-- =============================================
-- 5. SELF JOIN — HIERARCHY
-- =============================================

-- Show employee with manager
SELECT
  e.name AS employee,
  m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;
-- LEFT JOIN → CEO (NULL manager) kept! ✅
-- INNER JOIN → CEO disappears! ❌

-- Employees earning more than manager
SELECT
  e.name AS employee,
  m.name AS manager,
  e.salary AS emp_salary,
  m.salary AS mgr_salary
FROM employees e
JOIN employees m ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;
-- INNER JOIN intentional!
-- No manager = can't compare = exclude!

-- =============================================
-- 6. JOIN WITH DATE CONDITIONS
-- =============================================

-- Orders within 90 days of customer joining
SELECT c.name, c.joined_date, o.order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= c.joined_date
AND o.order_date <= DATE_ADD(c.joined_date, INTERVAL 90 DAY);

-- Customers with NO orders in first 90 days
-- Date condition in ON → not WHERE!
SELECT c.name
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
  AND o.order_date >= c.joined_date
  AND o.order_date <= DATE_ADD(c.joined_date, INTERVAL 90 DAY)
WHERE o.order_id IS NULL;

-- BETWEEN PITFALL:
-- ❌ BETWEEN '2023-01-01' AND '2023-03-31'
--    Misses: 2023-03-31 23:59:59!

-- ✅ Safe way:
WHERE order_date >= '2023-01-01'
AND order_date < '2023-04-01'  -- first day of next month!

-- =============================================
-- 7. COUNT(DISTINCT) AFTER JOIN
-- =============================================

-- WRONG → COUNT(*) = row count not entity count!
SELECT c.city,
  COUNT(*) AS total_customers  -- inflated!
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city;

-- CORRECT → COUNT(DISTINCT) deduplicates!
SELECT c.city,
  COUNT(DISTINCT c.customer_id) AS total_customers,
  COUNT(o.order_id) AS total_orders,
  COALESCE(SUM(o.amount), 0) AS total_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city;

-- RULE:
-- After JOIN → COUNT(DISTINCT parent_id)
-- COUNT(*) → counts rows not entities!

-- =============================================
-- 8. INNER vs LEFT JOIN DECISION
-- =============================================

-- Use LEFT JOIN when:
-- → Want ALL rows from left table
-- → Including those with no match
-- → Finding missing records
-- → Hierarchy with root nodes (CEO)
-- → Optional relationship

-- Use INNER JOIN when:
-- → Only want matching rows from both
-- → Comparison requires both sides
-- → Salary/performance comparison
-- → Required relationship

-- =============================================
-- 9. ALL JOIN TYPES — QUICK REFERENCE
-- =============================================

-- INNER JOIN    → only matching rows
-- LEFT JOIN     → all left + matching right
-- RIGHT JOIN    → all right + matching left
-- FULL OUTER    → all rows from both sides
-- CROSS JOIN    → every row × every row
-- SELF JOIN     → table joins itself
-- SEMI JOIN     → left rows WHERE match EXISTS
-- ANTI JOIN     → left rows WHERE NO match

-- =============================================
-- KEY RULES TO REMEMBER
-- =============================================

-- RULE 1: ON vs WHERE
-- Right table filter → ON condition
-- Result filter → WHERE condition
-- WHERE on right table = silent INNER JOIN!

-- RULE 2: Pre-aggregation
-- Multiple one-to-many tables → pre-aggregate!
-- Join raw → duplicate explosion!

-- RULE 3: COUNT(DISTINCT)
-- Always after JOIN for entity counts!
-- COUNT(*) counts rows not entities!

-- RULE 4: NOT EXISTS > NOT IN
-- NOT IN breaks with NULLs silently!
-- NOT EXISTS always NULL safe!

-- RULE 5: CROSS JOIN
-- Always intentional!
-- Missing JOIN condition = accidental CROSS JOIN!

-- RULE 6: Self JOIN aliasing
-- Always alias twice → e (employee), m (manager)
-- LEFT JOIN for root level preservation
