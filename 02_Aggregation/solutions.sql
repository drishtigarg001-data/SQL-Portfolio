-- =============================================
-- AGGREGATION — SOLUTIONS
-- =============================================
-- Format: Topic → Solution + Key Points
-- =============================================

-- =============================================
-- TOPIC 1: COUNT VARIATIONS
-- =============================================

-- Q1. Exact output:
SELECT
  COUNT(*)                    AS a,  -- 7 (all rows)
  COUNT(amount)               AS b,  -- 6 (NULL skipped)
  COUNT(DISTINCT ref_code)    AS c   -- 3 (REF001,REF002,REF003)
FROM orders;
-- NULL ref_codes skipped!
-- REF001 appears twice but counted once!

-- Q2. COUNT(COALESCE) trap:
-- COUNT(COALESCE(amount, 0))
-- COALESCE converts NULL → 0
-- 0 is NOT NULL → COUNT counts it!
-- Result = COUNT(*) always!
-- Never use COALESCE inside COUNT!

-- Q3. COUNT(*) vs COUNT(DISTINCT) after JOIN:
-- After one-to-many JOIN:
-- Alice has 3 orders → appears 3 times
-- COUNT(*) = 3 (rows) ← WRONG!
-- COUNT(DISTINCT customer_id) = 1 ← CORRECT!
-- Always use COUNT(DISTINCT parent_id) after JOIN!

-- =============================================
-- TOPIC 2: NULL BEHAVIOR IN AGGREGATION
-- =============================================

-- Q1. Exact output:
SELECT
  SUM(amount),    -- 2500 (NULLs ignored)
  AVG(amount),    -- 500  (2500/5 non-NULLs)
  MIN(amount),    -- 300  (NULLs ignored)
  MAX(amount),    -- 700  (NULLs ignored)
  COUNT(amount),  -- 5    (NULLs skipped)
  COUNT(*)        -- 7    (all rows)
FROM sales;

-- Q2. AVG trap:
-- AVG = SUM(non-NULL) / COUNT(non-NULL)
-- = 2500 / 5 = 500 ✅
-- NOT = 2500 / 7 = 357 ❌ (using COUNT(*))

-- Q3. All-NULL group:
-- R4 has only NULL discount
-- AVG(NULL) = NULL not 0!
-- Wrap with: COALESCE(AVG(discount), 0)

-- Q4. Safe NULL handling:
-- a) NULL as 0 in AVG:
SELECT AVG(COALESCE(amount, 0)) FROM sales;

-- b) NULL result to 0:
SELECT COALESCE(SUM(amount), 0) FROM sales;

-- c) Safe division:
SELECT completed / NULLIF(total, 0) AS rate FROM summary;

-- KEY POINTS:
-- NULL = unknown, NOT zero!
-- Aggregates IGNORE NULLs
-- All-NULL group → NULL result
-- COALESCE → NULL to value
-- NULLIF → value to NULL (safe division)

-- =============================================
-- TOPIC 3: CASE WHEN IN AGGREGATION
-- =============================================

-- Q1. Per customer counts:
SELECT
  customer_id,
  COUNT(order_id) AS total_orders,
  COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed,
  COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled
FROM orders
GROUP BY customer_id;
-- COUNT + CASE → no ELSE needed!
-- NULL = skip automatically!

-- Q2. Per customer amounts:
SELECT
  customer_id,
  SUM(amount) AS total_amount,
  SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) AS completed_amt,
  SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS pending_amt
FROM orders
GROUP BY customer_id;
-- SUM + CASE → ELSE 0 needed!

-- Q3. COUNT with ELSE 0 trap:
-- COUNT(CASE WHEN status='completed' THEN 1 ELSE 0 END)
-- 0 is NOT NULL → COUNT counts it!
-- Returns total row count not completed count!
-- Fix: Remove ELSE → COUNT(CASE WHEN ... THEN 1 END)

-- Q4. AVG with ELSE 0 trap:
-- AVG(CASE WHEN category='Electronics' THEN amount END)
-- = AVG of Electronics only = 420 ✅

-- AVG(CASE WHEN category='Electronics' THEN amount ELSE 0 END)
-- = Clothing rows get 0 → dilutes average!
-- = 240 ❌ Wrong!

-- KEY POINTS:
-- COUNT + CASE → NO ELSE (NULL = skip)
-- SUM + CASE → ELSE 0 (adds nothing)
-- AVG + CASE → NO ELSE 0 (dilutes average!)

-- =============================================
-- TOPIC 4: HAVING vs WHERE
-- =============================================

-- Q1. Wrong query explanation:
-- WHERE SUM(amount) > 1000 → ERROR!
-- SQL order: FROM→WHERE→GROUP BY→HAVING→SELECT
-- WHERE runs BEFORE GROUP BY
-- SUM not calculated yet at WHERE stage!

-- Q2. Fixed query:
SELECT rep_id, SUM(amount) AS total
FROM sales
GROUP BY rep_id
HAVING SUM(amount) > 1000;

-- Q3. Combined WHERE + HAVING:
SELECT rep_id, SUM(amount) AS total
FROM sales
WHERE region = 'North'           -- row filter first
GROUP BY rep_id
HAVING SUM(amount) > 800         -- group filter after
AND COUNT(CASE WHEN status = 'completed'
          THEN 1 END) > 1;

-- Q4. HAVING without GROUP BY:
-- Treats entire table as ONE group!
SELECT SUM(amount) AS total
FROM sales
HAVING SUM(amount) > 5000;
-- Returns total only if condition met
-- Returns nothing if not met!

-- KEY POINTS:
-- WHERE → before GROUP BY → no aggregates!
-- HAVING → after GROUP BY → aggregates allowed!
-- Both together → WHERE reduces data first → faster!
-- HAVING without GROUP BY → whole table = one group

-- =============================================
-- TOPIC 5: AGGREGATION AFTER JOINS
-- =============================================

-- Q1. Wrong query explanation:
-- Alice has 3 orders + 2 payments
-- JOIN creates 3×2 = 6 rows for Alice
-- SUM(orders) = inflated × 2
-- SUM(payments) = inflated × 3

-- Q2. Fixed query — pre-aggregate first:
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

-- Q3. Per city query:
SELECT
  c.city,
  COUNT(DISTINCT c.customer_id) AS total_customers,
  COUNT(o.order_id) AS total_orders,
  COALESCE(SUM(o.amount), 0) AS total_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city;

-- Q4. COUNT difference:
-- COUNT(c.customer_id) → counts rows
--   Alice with 3 orders → counted 3 times!
-- COUNT(DISTINCT c.customer_id) → counts unique
--   Alice → counted once! ✅

-- KEY POINTS:
-- Multiple one-to-many → pre-aggregate!
-- COUNT(DISTINCT) after JOIN always!
-- COALESCE(SUM(), 0) for NULL groups!
-- LEFT JOIN for all parent records!

-- =============================================
-- TOPIC 6: MAX/MIN PER GROUP WITH TIES
-- =============================================

-- Q1. Highest salary per department:
SELECT dept, MAX(salary) AS max_salary
FROM employees
GROUP BY dept;

-- Q2. Employees at max salary (handles ties!):
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
-- Alice AND Bob both returned for Tech! ✅

-- Q3. Wrong query explanation:
-- SELECT dept, name, MAX(salary) GROUP BY dept
-- name not in GROUP BY!
-- PostgreSQL/BigQuery → ERROR!
-- MySQL → random name returned!

-- Q4. Departments with tied max salary:
WITH dept_max AS (
  SELECT dept, MAX(salary) AS max_sal
  FROM employees GROUP BY dept
),
tie_check AS (
  SELECT e.dept, COUNT(*) AS top_count
  FROM employees e
  JOIN dept_max d
    ON e.dept = d.dept
    AND e.salary = d.max_sal
  GROUP BY e.dept
  HAVING COUNT(*) > 1
)
SELECT e.dept, e.name, e.salary
FROM employees e
JOIN dept_max d ON e.dept = d.dept
  AND e.salary = d.max_sal
JOIN tie_check tc ON e.dept = tc.dept;

-- KEY POINTS:
-- CTE + JOIN → handles ties correctly!
-- GROUP BY dept alone → loses individual names!
-- RANK() alternative for top N per group!

-- =============================================
-- TOPIC 7: AGGREGATE vs WINDOW FUNCTIONS
-- =============================================

-- Q1. Fundamental difference:
-- GROUP BY → collapses rows → only group data visible
-- Window   → retains all rows → row + group data visible

-- Q2. Two approaches:

-- GROUP BY + JOIN:
WITH rep_totals AS (
  SELECT rep_id, SUM(amount) AS rep_total
  FROM sales GROUP BY rep_id
)
SELECT s.sale_id, s.rep_id, s.amount, r.rep_total
FROM sales s
JOIN rep_totals r ON s.rep_id = r.rep_id;

-- Window Function (cleaner!):
SELECT
  sale_id, rep_id, amount,
  SUM(amount) OVER(PARTITION BY rep_id) AS rep_total
FROM sales;

-- Q3. Wrong query explanation:
-- Cannot mix regular aggregate + window function
-- in same SELECT without subquery/CTE!
-- SUM(amount) needs GROUP BY
-- SUM() OVER() doesn't use GROUP BY
-- Conflict → ERROR!

-- Fix:
SELECT
  rep_id, amount,
  SUM(amount) OVER(PARTITION BY rep_id) AS rep_total,
  SUM(amount) OVER() AS overall_total
FROM sales;

-- Q4. When to use which:
-- GROUP BY → final summary only needed
-- Window   → row + group data together needed
--          → rankings, running totals, LAG/LEAD

-- KEY POINTS:
-- Window functions never collapse rows!
-- PARTITION BY = group wise calculation
-- No PARTITION BY = overall calculation
-- Cannot mix aggregate + window in same SELECT!

-- =============================================
-- TOPIC 8: SUM/AVG CONDITIONAL EXPRESSIONS
-- =============================================

-- Q1. Per month query:
SELECT
  month,
  SUM(amount) AS total_revenue,
  SUM(CASE WHEN category = 'Electronics'
      THEN amount ELSE 0 END) AS electronics_rev,
  SUM(CASE WHEN status = 'completed'
      THEN amount ELSE 0 END) AS completed_rev,
  ROUND(
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END)
    * 100.0 / COUNT(order_id),
  2) AS cancelled_pct
FROM orders
GROUP BY month;

-- Q2. Per customer query:
SELECT
  customer_id,
  SUM(amount) AS total_amt,
  SUM(CASE WHEN status = 'completed'
      THEN amount ELSE 0 END) AS completed_amt,
  SUM(CASE WHEN category = 'Electronics'
      AND status = 'completed'
      THEN amount ELSE 0 END) AS elec_completed,
  CASE
    WHEN SUM(amount) > 800 THEN 'High Value'
    ELSE 'Regular'
  END AS flag
FROM orders
GROUP BY customer_id;

-- Q3. AVG difference:
-- No ELSE → AVG of Electronics only = 420 ✅
-- ELSE 0  → Clothing rows get 0 → avg = 240 ❌

-- KEY POINTS:
-- Multi-condition: CASE WHEN col1=x AND col2=y
-- % calculation: COUNT(CASE...) * 100.0 / COUNT(*)
-- Flag on group: CASE WHEN SUM(col) > x THEN...
-- AVG + CASE → NEVER use ELSE 0!

-- =============================================
-- TOPIC 9: DISTINCT IN AGGREGATION
-- =============================================

-- Q1. Exact output:
-- a = 10 (all rows)
-- b = 4  (C1,C2,C3,C4 unique)
-- c = 3  (P1,P2,P3 unique)

-- Q2. SUM(DISTINCT) danger:
-- amounts: 500,500,300,500,400,500,300,300,400,400
-- DISTINCT amounts: 500, 300, 400
-- SUM(DISTINCT) = 1200 ← WRONG!
-- Real total = 4100
-- Lost 2900! Silent bug!

-- Q3. Per category query:
SELECT
  category,
  COUNT(txn_id) AS total_transactions,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT product_id) AS unique_products,
  SUM(CASE WHEN status='completed'
      THEN amount ELSE 0 END) AS total_revenue
FROM transactions
GROUP BY category;

-- Q4. COUNT DISTINCT difference:
-- COUNT(DISTINCT c_id, p_id) = 7
--   → actual unique combinations
-- COUNT(DISTINCT c_id) * COUNT(DISTINCT p_id) = 4*3 = 12
--   → assumes ALL combinations exist → WRONG!

-- KEY POINTS:
-- COUNT(DISTINCT) → safe, common ✅
-- SUM(DISTINCT)   → almost always wrong! ⚠️
-- Multi-column DISTINCT → MySQL only!
-- Multiply DISTINCTs → assumes all combinations!

-- =============================================
-- TOPIC 10: AGGREGATION ON DERIVED COLUMNS
-- =============================================

-- Q1. Per rep query using CTE:
WITH calculated AS (
  SELECT
    rep_id,
    amount,
    amount * (1 - discount_pct/100) AS discounted,
    amount * (1 - discount_pct/100)
            * (1 + tax_pct/100) AS net_amount
  FROM sales
)
SELECT
  rep_id,
  SUM(amount) AS total_amount,
  SUM(discounted) AS total_after_discount,
  SUM(net_amount) AS total_after_tax,
  AVG(net_amount) AS avg_net_per_sale
FROM calculated
GROUP BY rep_id;

-- Q2. Wrong query explanation:
-- SELECT alias 'discounted' used in same SELECT
-- SQL runs SELECT almost last!
-- 'discounted' doesn't exist yet when SUM runs!
-- Fix: Use CTE or repeat full expression!

-- Q3. Filter on net revenue:
WITH calculated AS (
  SELECT rep_id,
    SUM(amount * (1-discount_pct/100)
               * (1+tax_pct/100)) AS net_total
  FROM sales GROUP BY rep_id
)
SELECT rep_id, net_total
FROM calculated
WHERE net_total > 2000;

-- Q4. SELECT alias in HAVING:
-- HAVING total_discounted > 2000 → ERROR!
-- HAVING runs before SELECT!
-- Fix: Repeat expression or use CTE!

-- KEY POINTS:
-- CTE for derived columns → reusable aliases!
-- Never reference SELECT alias in WHERE/HAVING!
-- Repeat expression or use CTE instead!
-- SQL order: FROM→WHERE→GROUP BY→HAVING→SELECT

-- =============================================
-- TOPIC 11: ROLLUP & CUBE
-- =============================================

-- Q1. Row count:
SELECT region, category, SUM(amount)
FROM sales
GROUP BY ROLLUP(region, category);
-- North + Electronics = 1100
-- North + Clothing    = 300
-- North subtotal      = 1400  ← NULL category
-- South + Electronics = 700
-- South + Clothing    = 400
-- South subtotal      = 1100  ← NULL category
-- Grand total         = 2500  ← NULL NULL
-- Total = 7 rows!

-- Q2. Single column ROLLUP vs CUBE:
-- Same result! Only 2 possibilities:
-- Individual groups + grand total
-- No extra combinations possible!

-- Q3. Two column difference:
-- ROLLUP → 3 levels: individual, region subtotal, grand total
-- CUBE   → 4 levels: individual, region subtotal,
--                    category subtotal, grand total
-- CUBE has category subtotal extra!

-- Q4. GROUPING() function:
SELECT
  CASE GROUPING(region)
    WHEN 1 THEN 'ALL REGIONS'
    ELSE region
  END AS region,
  CASE GROUPING(category)
    WHEN 1 THEN 'ALL CATEGORIES'
    ELSE category
  END AS category,
  SUM(amount) AS total
FROM sales
GROUP BY ROLLUP(region, category);

-- KEY POINTS:
-- ROLLUP → hierarchical subtotals
-- CUBE → all possible combination subtotals
-- Single column → same result!
-- GROUPING() → distinguish NULL subtotal vs actual NULL

-- =============================================
-- TOPIC 12: DUPLICATE HANDLING
-- =============================================

-- Q1. Find exact duplicates:
SELECT
  customer_id, product_id, amount,
  status, created_at,
  COUNT(*) AS duplicate_count
FROM orders
GROUP BY customer_id, product_id, amount,
         status, created_at
HAVING COUNT(*) > 1;
-- Rows 4&5 → exact duplicates (C2,P1,500,pending)
-- Rows 7&8 → exact duplicates (C3,P2,300,completed)

-- Q2. Keep latest record:
WITH ranked AS (
  SELECT *,
    ROW_NUMBER() OVER(
      PARTITION BY customer_id, product_id
      ORDER BY created_at DESC
    ) AS rn
  FROM orders
)
SELECT * FROM ranked WHERE rn = 1;

-- Q3. Delete duplicates:
DELETE FROM orders
WHERE order_id NOT IN (
  SELECT MIN(order_id)
  FROM orders
  GROUP BY customer_id, product_id,
           amount, status, created_at
);

-- Q4. Pipeline deduplication:
-- NOT EXISTS approach:
INSERT INTO final_table
SELECT s.*
FROM staging s
WHERE NOT EXISTS (
  SELECT 1 FROM final_table f
  WHERE f.customer_id = s.customer_id
  AND f.created_at = s.created_at
);

-- MERGE approach (preferred in production!):
MERGE INTO final_table f
USING staging s
ON f.customer_id = s.customer_id
  AND f.created_at = s.created_at
WHEN NOT MATCHED THEN
  INSERT VALUES(s.order_id, s.customer_id,
                s.amount, s.created_at);

-- KEY POINTS:
-- Exact duplicates → GROUP BY all columns + HAVING!
-- Keep latest → ROW_NUMBER() PARTITION BY business key!
-- Delete → NOT IN + MIN(id)!
-- Pipeline → MERGE statement preferred!
-- ROW_NUMBER vs RANK → ties handle differently!

-- =============================================
-- TOPIC 13: GROUP BY DEEP PRACTICE SOLUTIONS
-- =============================================

-- PROBLEM 1: Employee Performance
SELECT
  dept,
  region,
  COUNT(emp_id) AS total_emp,
  COALESCE(AVG(salary), 0) AS avg_salary,
  COUNT(CASE WHEN rating = 5 THEN 1 END) AS rating_5,
  COUNT(CASE WHEN rating >= 4 THEN 1 END) AS rating_4_plus,
  MAX(salary) AS highest_sal,
  MIN(salary) AS lowest_sal,
  MAX(salary) - MIN(salary) AS salary_range,
  ROUND(COUNT(CASE WHEN rating = 5 THEN 1 END)
    * 100.0 / COUNT(*), 2) AS pct_rating_5,
  CASE
    WHEN AVG(rating) > 4 THEN 'Star Team'
    WHEN AVG(rating) >= 3 THEN 'Good Team'
    ELSE 'Needs Work'
  END AS team_label
FROM employee_performance
GROUP BY dept, region
HAVING COUNT(*) >= 2;

-- PROBLEM 2: Customers + Orders
WITH order_category AS (
  SELECT customer_id,
    COUNT(CASE WHEN category='Electronics' THEN 1 END) AS elec,
    COUNT(CASE WHEN category='Clothing' THEN 1 END) AS cloth
  FROM orders GROUP BY customer_id
),
customer_activity AS (
  SELECT customer_id,
    CASE WHEN COUNT(order_id) > 2
      THEN 'High Activity'
      ELSE 'Low Activity'
    END AS activity_label
  FROM orders GROUP BY customer_id
)
SELECT
  c.city, c.segment,
  COUNT(DISTINCT c.customer_id) AS total_customers,
  COUNT(o.order_id) AS total_orders,
  SUM(o.amount) AS total_revenue,
  ROUND(AVG(o.amount), 2) AS avg_order_value,
  SUM(CASE WHEN o.status='completed'
      THEN o.amount ELSE 0 END) AS completed_rev,
  ROUND(COUNT(CASE WHEN o.status='cancelled' THEN 1 END)
    * 100.0 / COUNT(o.order_id), 2) AS cancel_pct,
  CASE
    WHEN SUM(oc.elec) > SUM(oc.cloth) THEN 'Electronics'
    WHEN SUM(oc.elec) < SUM(oc.cloth) THEN 'Clothing'
    ELSE 'Equal'
  END AS top_category,
  MAX(ca.activity_label) AS activity
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_category oc ON c.customer_id = oc.customer_id
LEFT JOIN customer_activity ca ON c.customer_id = ca.customer_id
GROUP BY c.city, c.segment
HAVING SUM(o.amount) > 500;

-- PROBLEM 3: Transactions
WITH category_count AS (
  SELECT customer_id,
    COUNT(CASE WHEN category='Electronics' THEN 1 END) AS elec,
    COUNT(CASE WHEN category='Clothing' THEN 1 END) AS cloth
  FROM transactions GROUP BY customer_id
),
customer_seg AS (
  SELECT customer_id,
    SUM(CASE WHEN status='completed'
        THEN amount ELSE 0 END) AS completed_amt
  FROM transactions GROUP BY customer_id
)
SELECT
  t.customer_id,
  COUNT(t.txn_id) AS total_txns,
  SUM(t.amount) AS total_amount,
  SUM(CASE WHEN t.status='completed'
      THEN t.amount ELSE 0 END) AS completed_amt,
  SUM(CASE WHEN t.status='cancelled'
      THEN t.amount ELSE 0 END) AS cancelled_amt,
  COUNT(DISTINCT t.product_id) AS unique_products,
  COUNT(DISTINCT t.category) AS unique_categories,
  MIN(t.txn_date) AS first_txn,
  MAX(t.txn_date) AS last_txn,
  MAX(t.txn_date) - MIN(t.txn_date) AS days_diff,
  CASE
    WHEN cc.elec > cc.cloth THEN 'Electronics'
    WHEN cc.elec < cc.cloth THEN 'Clothing'
    ELSE 'Both Equal'
  END AS top_category,
  CASE
    WHEN cs.completed_amt > 1500 THEN 'Champion'
    WHEN cs.completed_amt BETWEEN 800 AND 1500 THEN 'Loyal'
    ELSE 'At Risk'
  END AS value_segment
FROM transactions t
LEFT JOIN category_count cc ON t.customer_id = cc.customer_id
LEFT JOIN customer_seg cs ON t.customer_id = cs.customer_id
GROUP BY t.customer_id, cc.elec, cc.cloth, cs.completed_amt
HAVING COUNT(CASE WHEN t.status='completed' THEN 1 END) >= 2;

-- PROBLEM 4: Sales Data
WITH region_perf AS (
  SELECT salesperson_id, quarter,
    SUM(CASE WHEN region='North'
        THEN sale_amount ELSE 0 END) AS north_sal,
    SUM(CASE WHEN region='South'
        THEN sale_amount ELSE 0 END) AS south_sal
  FROM sales_data GROUP BY salesperson_id, quarter
),
qoq_growth AS (
  SELECT salesperson_id,
    SUM(CASE WHEN quarter='Q1'
        THEN sale_amount ELSE 0 END) AS q1,
    SUM(CASE WHEN quarter='Q2'
        THEN sale_amount ELSE 0 END) AS q2,
    COUNT(CASE WHEN quarter='Q1' THEN 1 END) AS q1_count,
    COUNT(CASE WHEN quarter='Q2' THEN 1 END) AS q2_count
  FROM sales_data GROUP BY salesperson_id
),
totals AS (
  SELECT salesperson_id, quarter,
    SUM(sale_amount) AS total
  FROM sales_data GROUP BY salesperson_id, quarter
)
SELECT
  sd.salesperson_id, sd.quarter,
  t.total AS total_sales,
  SUM(sd.units_sold) AS total_units,
  ROUND(AVG(sd.sale_amount), 2) AS avg_sale,
  ROUND(SUM(sd.sale_amount)
    / NULLIF(SUM(sd.units_sold), 0), 2) AS rev_per_unit,
  SUM(CASE WHEN sd.product_category='Electronics'
      THEN sd.sale_amount ELSE 0 END) AS elec_rev,
  SUM(CASE WHEN sd.product_category='Clothing'
      THEN sd.sale_amount ELSE 0 END) AS cloth_rev,
  ROUND(SUM(CASE WHEN sd.product_category='Electronics'
      THEN sd.sale_amount ELSE 0 END)
    * 100.0 / NULLIF(SUM(sd.sale_amount), 0), 2) AS elec_pct,
  CASE
    WHEN rp.north_sal > rp.south_sal THEN 'North'
    WHEN rp.north_sal < rp.south_sal THEN 'South'
    ELSE 'Equal'
  END AS best_region,
  CASE
    WHEN qg.q2_count = 0 THEN 'Only Q1'
    WHEN qg.q1_count = 0 THEN 'Only Q2'
    WHEN qg.q1 < qg.q2 THEN 'Growth'
    WHEN qg.q1 > qg.q2 THEN 'Decline'
    ELSE 'Same'
  END AS growth_label,
  CASE
    WHEN t.total > 25000 THEN 'Top Performer'
    WHEN t.total BETWEEN 15000 AND 25000 THEN 'Mid Performer'
    ELSE 'Low Performer'
  END AS performance
FROM sales_data sd
LEFT JOIN region_perf rp
  ON sd.salesperson_id = rp.salesperson_id
  AND sd.quarter = rp.quarter
LEFT JOIN qoq_growth qg ON sd.salesperson_id = qg.salesperson_id
LEFT JOIN totals t
  ON sd.salesperson_id = t.salesperson_id
  AND sd.quarter = t.quarter
GROUP BY sd.salesperson_id, sd.quarter,
         rp.north_sal, rp.south_sal,
         qg.q1, qg.q2, qg.q1_count, qg.q2_count,
         t.total
HAVING COUNT(*) >= 2;

-- PROBLEM 5: Hospital Data
WITH global_cal AS (
  SELECT doctor_id, department,
    AVG(treatment_cost) AS avg_cost,
    ROUND(COUNT(CASE WHEN status='cancelled' THEN 1 END)
      * 100.0 / NULLIF(COUNT(*), 0), 2) AS cancel_pct
  FROM hospital_data GROUP BY doctor_id, department
),
diagnosis_rank AS (
  SELECT doctor_id, department, diagnosis,
    COUNT(*) AS diag_count,
    RANK() OVER(
      PARTITION BY doctor_id, department
      ORDER BY COUNT(*) DESC
    ) AS rnk
  FROM hospital_data
  GROUP BY doctor_id, department, diagnosis
),
diagnosis_winner AS (
  SELECT doctor_id, department,
    COUNT(*) AS tie_count,
    MAX(diagnosis) AS top_diagnosis
  FROM diagnosis_rank
  WHERE rnk = 1
  GROUP BY doctor_id, department
)
SELECT
  hd.department, hd.doctor_id,
  COUNT(hd.patient_id) AS total_visits,
  COUNT(DISTINCT hd.patient_id) AS unique_patients,
  SUM(hd.treatment_cost) AS total_cost,
  gc.avg_cost AS avg_cost,
  SUM(CASE WHEN hd.status='completed'
      THEN hd.treatment_cost ELSE 0 END) AS completed_rev,
  COUNT(CASE WHEN hd.status='cancelled'
        THEN 1 END) AS cancelled_count,
  gc.cancel_pct,
  CASE
    WHEN dw.tie_count > 1 THEN 'Multiple'
    ELSE dw.top_diagnosis
  END AS common_diagnosis,
  CASE
    WHEN gc.avg_cost > 40000 THEN 'Premium'
    WHEN gc.avg_cost BETWEEN 20000 AND 40000 THEN 'Standard'
    ELSE 'Budget'
  END AS cost_label,
  CASE
    WHEN gc.cancel_pct = 0 THEN 'Excellent'
    WHEN gc.cancel_pct < 20 THEN 'Good'
    ELSE 'Needs Review'
  END AS doctor_perf
FROM hospital_data hd
LEFT JOIN global_cal gc
  ON hd.doctor_id = gc.doctor_id
  AND hd.department = gc.department
LEFT JOIN diagnosis_winner dw
  ON hd.doctor_id = dw.doctor_id
  AND hd.department = dw.department
GROUP BY hd.department, hd.doctor_id,
         gc.avg_cost, gc.cancel_pct,
         dw.tie_count, dw.top_diagnosis
HAVING COUNT(*) >= 2;

-- PROBLEM 6: Ecommerce Data
WITH calculation AS (
  SELECT seller_id, category,
    ROUND(COUNT(CASE WHEN status='cancelled' THEN 1 END)
      * 100.0 / NULLIF(COUNT(order_id), 0), 2) AS cancel_pct,
    AVG(CASE WHEN status='delivered'
        THEN DATEDIFF(day, order_date, delivery_date)
        END) AS avg_del_days
  FROM ecommerce_data
  GROUP BY seller_id, category
)
SELECT
  ed.seller_id, ed.category,
  COUNT(ed.order_id) AS total_orders,
  COUNT(DISTINCT ed.customer_id) AS unique_customers,
  SUM(ed.amount - ed.discount + ed.tax) AS net_revenue,
  ROUND(SUM(ed.amount - ed.discount + ed.tax)
    / NULLIF(COUNT(ed.order_id), 0), 2) AS avg_net_per_order,
  COUNT(CASE WHEN ed.status='delivered'
        THEN 1 END) AS delivered_count,
  COUNT(CASE WHEN ed.status='cancelled'
        THEN 1 END) AS cancelled_count,
  cal.cancel_pct,
  cal.avg_del_days,
  SUM(ed.units) AS total_units,
  ROUND(SUM(ed.amount - ed.discount + ed.tax)
    / NULLIF(SUM(ed.units), 0), 2) AS rev_per_unit,
  ROUND(SUM(ed.discount) * 100.0
    / NULLIF(SUM(ed.amount), 0), 2) AS discount_pct,
  CASE
    WHEN cal.cancel_pct = 0
     AND cal.avg_del_days <= 7 THEN 'Star'
    WHEN cal.cancel_pct < 20
     AND cal.avg_del_days <= 10 THEN 'Good'
    WHEN cal.cancel_pct < 30 THEN 'Average'
    ELSE 'Poor'
  END AS performance
FROM ecommerce_data ed
LEFT JOIN calculation cal
  ON ed.seller_id = cal.seller_id
  AND ed.category = cal.category
GROUP BY ed.seller_id, ed.category,
         cal.cancel_pct, cal.avg_del_days
HAVING COUNT(*) >= 2;

-- =============================================
-- KEY TAKEAWAYS — AGGREGATION
-- =============================================

-- 1. AVG trap → divides by COUNT(non-NULL) not COUNT(*)
-- 2. NULL ≠ 0 → aggregates IGNORE NULLs
-- 3. COUNT+CASE → no ELSE | SUM+CASE → ELSE 0
-- 4. AVG+CASE → NEVER ELSE 0!
-- 5. Pre-aggregate before multiple JOINs!
-- 6. COUNT(DISTINCT) after JOIN always!
-- 7. NULLIF for safe division always!
-- 8. CTE for complex derived columns!
-- 9. RANK() for ties | ROW_NUMBER() for unique!
-- 10. ROLLUP=hierarchical | CUBE=all combinations!
