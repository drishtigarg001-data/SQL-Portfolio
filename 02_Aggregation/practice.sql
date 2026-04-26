-- =============================================
-- AGGREGATION — PRACTICE QUESTIONS
-- =============================================
-- Format: Dataset → Question → Hint
-- Solutions: See solutions.sql
-- =============================================

-- =============================================
-- TOPIC 1: COUNT VARIATIONS
-- =============================================

-- Dataset:
-- orders table
-- order_id | customer_id | amount | status    | ref_code
-- ---------|-------------|--------|-----------|----------
-- 101      | 1           | 500    | completed | REF001
-- 102      | 1           | 300    | pending   | REF002
-- 103      | 2           | 700    | completed | NULL
-- 104      | 2           | 200    | cancelled | REF001
-- 105      | 3           | 400    | completed | NULL
-- 106      | 3           | NULL   | pending   | REF003
-- 107      | 4           | 600    | completed | NULL

-- Q1. What is the exact output of a, b, c?
-- SELECT
--   COUNT(*)                  AS a,
--   COUNT(amount)             AS b,
--   COUNT(DISTINCT ref_code)  AS c
-- FROM orders;

-- Q2. Why is COUNT(COALESCE(amount, 0)) dangerous?
-- Hint: What does COALESCE do to NULL?
--       What does COUNT do with non-NULL values?

-- Q3. What is difference between:
--   COUNT(DISTINCT customer_id) vs
--   COUNT(*) after a JOIN?
-- Hint: Think about duplicate explosion after JOIN!

-- =============================================
-- TOPIC 2: NULL BEHAVIOR IN AGGREGATION
-- =============================================

-- Dataset:
-- sales table
-- sale_id | rep_id | amount | discount
-- --------|--------|--------|----------
-- 1       | R1     | 500    | 10
-- 2       | R1     | 300    | NULL
-- 3       | R2     | 700    | 20
-- 4       | R2     | NULL   | NULL
-- 5       | R3     | 400    | 5
-- 6       | R3     | NULL   | 15
-- 7       | R4     | 600    | NULL

-- Q1. What is exact output of:
-- SELECT
--   SUM(amount), AVG(amount), MIN(amount),
--   MAX(amount), COUNT(amount), COUNT(*)
-- FROM sales;
-- Hint: Remember AVG formula!

-- Q2. Someone says:
--   "AVG(amount) = SUM(amount) / COUNT(*)"
-- Is this correct? Show with numbers.
-- Hint: What does AVG actually divide by?

-- Q3. What does AVG(discount) return for R4?
-- SELECT rep_id, AVG(discount) FROM sales GROUP BY rep_id;
-- Hint: What happens when ALL values in group are NULL?

-- Q4. How do you safely handle:
--   a) NULL treated as 0 in AVG
--   b) NULL result from aggregation
--   c) Division by zero
-- Hint: COALESCE, NULLIF

-- =============================================
-- TOPIC 3: CASE WHEN IN AGGREGATION
-- =============================================

-- Dataset:
-- orders table
-- order_id | customer_id | amount | status    | category
-- ---------|-------------|--------|-----------|----------
-- 1        | C1          | 500    | completed | Electronics
-- 2        | C1          | 300    | cancelled | Clothing
-- 3        | C2          | 700    | completed | Electronics
-- 4        | C2          | 200    | cancelled | Clothing
-- 5        | C3          | 400    | completed | Electronics
-- 6        | C3          | 600    | completed | Clothing
-- 7        | C4          | 150    | cancelled | Electronics
-- 8        | C4          | 800    | completed | Clothing

-- Q1. Write query per customer:
--   total orders, completed count, cancelled count
-- Hint: COUNT + CASE → no ELSE needed!

-- Q2. Write query per customer:
--   total amount, completed amount, pending amount
-- Hint: SUM + CASE → ELSE 0 needed!

-- Q3. What is wrong with this?
-- COUNT(CASE WHEN status = 'completed' THEN 1 ELSE 0 END)
-- Hint: What does COUNT do with 0?
--       What does COUNT do with NULL?

-- Q4. What is difference between:
-- AVG(CASE WHEN category='Electronics' THEN amount END)
-- vs
-- AVG(CASE WHEN category='Electronics' THEN amount ELSE 0 END)
-- Hint: ELSE 0 includes non-Electronics in denominator!

-- =============================================
-- TOPIC 4: HAVING vs WHERE
-- =============================================

-- Dataset:
-- sales table
-- sale_id | rep_id | region | amount | status
-- --------|--------|--------|--------|----------
-- 1       | R1     | North  | 500    | completed
-- 2       | R1     | North  | 300    | cancelled
-- 3       | R1     | South  | 700    | completed
-- 4       | R2     | North  | 400    | completed
-- 5       | R2     | South  | 600    | cancelled
-- 6       | R2     | South  | 200    | completed
-- 7       | R3     | North  | 150    | cancelled
-- 8       | R3     | North  | 800    | completed
-- 9       | R3     | South  | NULL   | completed

-- Q1. What is wrong with this query?
-- SELECT rep_id, SUM(amount) AS total
-- FROM sales
-- WHERE SUM(amount) > 1000
-- GROUP BY rep_id;
-- Hint: SQL execution order!

-- Q2. Fix the above query correctly.
-- Hint: Where should aggregate filter go?

-- Q3. Write query: reps with more than 1 completed order
--   AND total amount > 800, only from North region
-- Hint: Which filters go in WHERE vs HAVING?

-- Q4. Can you use HAVING without GROUP BY?
-- What happens?
-- Hint: Entire table = one group!

-- =============================================
-- TOPIC 5: AGGREGATION AFTER JOINS
-- =============================================

-- Dataset:
-- customers (customer_id, name, city)
-- orders (order_id, customer_id, amount, category)
-- payments (payment_id, customer_id, amount)

-- Q1. What is wrong with this?
-- SELECT c.name,
--   SUM(o.amount) AS total_orders,
--   SUM(p.amount) AS total_payments
-- FROM customers c
-- LEFT JOIN orders o ON c.customer_id = o.customer_id
-- LEFT JOIN payments p ON c.customer_id = p.customer_id
-- GROUP BY c.name;
-- Hint: Duplicate explosion!

-- Q2. Fix the above query correctly.
-- Hint: Pre-aggregate before joining!

-- Q3. Write query per city:
--   total customers, total orders, total revenue
-- Hint: COUNT(DISTINCT) for customers!

-- Q4. What is difference between:
-- COUNT(c.customer_id) vs COUNT(DISTINCT c.customer_id)
-- after a LEFT JOIN?
-- Hint: One-to-many relationship!

-- =============================================
-- TOPIC 6: MAX/MIN PER GROUP WITH TIES
-- =============================================

-- Dataset:
-- employees table
-- emp_id | name    | dept    | salary
-- -------|---------|---------|-------
-- 1      | Alice   | Tech    | 80000
-- 2      | Bob     | Tech    | 80000
-- 3      | Charlie | Tech    | 60000
-- 4      | David   | HR      | 50000
-- 5      | Eve     | HR      | 70000
-- 6      | Frank   | HR      | 70000
-- 7      | Grace   | Finance | 90000
-- 8      | Henry   | Finance | 55000
-- 9      | Ivan    | Finance | 55000

-- Q1. Write query: highest salary per department
-- Hint: Simple MAX GROUP BY

-- Q2. Write query: employees earning highest salary
--   in their department (handle ties!)
-- Hint: CTE + JOIN approach

-- Q3. What is wrong with this?
-- SELECT dept, name, MAX(salary)
-- FROM employees
-- GROUP BY dept;
-- Hint: name not in GROUP BY!

-- Q4. Write query: departments where top salary has a tie
-- Hint: COUNT employees at max salary > 1

-- =============================================
-- TOPIC 7: AGGREGATE vs WINDOW FUNCTIONS
-- =============================================

-- Dataset:
-- sales table
-- sale_id | rep_id | region | amount | sale_date
-- --------|--------|--------|--------|------------
-- 1       | R1     | North  | 500    | 2023-01-10
-- 2       | R1     | North  | 300    | 2023-02-15
-- 3       | R1     | South  | 700    | 2023-03-20
-- 4       | R2     | North  | 400    | 2023-01-25
-- 5       | R2     | South  | 600    | 2023-02-10
-- 6       | R2     | South  | 200    | 2023-03-15
-- 7       | R3     | North  | 800    | 2023-01-30
-- 8       | R3     | South  | 350    | 2023-02-20
-- 9       | R3     | North  | 450    | 2023-03-10

-- Q1. What is fundamental difference between
--   GROUP BY aggregation and Window Functions?
-- Hint: Rows collapse vs rows retained!

-- Q2. Write two queries:
--   Show each sale WITH rep's total sales
--   Once using GROUP BY + JOIN
--   Once using Window Function
-- Hint: SUM() OVER(PARTITION BY rep_id)

-- Q3. What is wrong with this?
-- SELECT rep_id, amount,
--   SUM(amount) OVER(PARTITION BY rep_id) AS rep_total,
--   SUM(amount) AS overall_total
-- FROM sales
-- GROUP BY rep_id;
-- Hint: Cannot mix aggregate + window in same level!

-- Q4. When would you choose GROUP BY over Window?
-- Hint: Summary only vs row + group data together

-- =============================================
-- TOPIC 8: SUM/AVG CONDITIONAL EXPRESSIONS
-- =============================================

-- Dataset:
-- orders table
-- order_id | customer_id | amount | category    | status  | month
-- ---------|-------------|--------|-------------|---------|------
-- 1        | C1          | 500    | Electronics | completed | Jan
-- 2        | C1          | 300    | Clothing    | cancelled | Jan
-- 3        | C2          | 700    | Electronics | completed | Jan
-- 4        | C2          | 200    | Clothing    | pending   | Feb
-- 5        | C3          | 400    | Electronics | completed | Feb
-- 6        | C3          | 600    | Clothing    | completed | Feb
-- 7        | C4          | 150    | Electronics | cancelled | Feb
-- 8        | C4          | 800    | Clothing    | completed | Jan
-- 9        | C5          | 350    | Electronics | pending   | Jan
-- 10       | C5          | 450    | Clothing    | cancelled | Feb

-- Q1. Write query per month:
--   total revenue, Electronics revenue,
--   completed revenue, cancelled % of total orders
-- Hint: COUNT for %, not SUM!

-- Q2. Write query per customer:
--   total amount, completed amount,
--   Electronics completed amount,
--   flag as High Value if total > 800 else Regular
-- Hint: Multi-condition CASE WHEN with AND!

-- Q3. What is difference between:
-- AVG(CASE WHEN category='Electronics' THEN amount END)
-- vs
-- AVG(CASE WHEN category='Electronics' THEN amount ELSE 0 END)
-- Hint: ELSE 0 dilutes denominator!

-- =============================================
-- TOPIC 9: DISTINCT IN AGGREGATION
-- =============================================

-- Dataset:
-- transactions table
-- txn_id | customer_id | product_id | amount | status
-- -------|-------------|------------|--------|----------
-- 1      | C1          | P1         | 500    | completed
-- 2      | C1          | P1         | 500    | completed
-- 3      | C1          | P2         | 300    | cancelled
-- 4      | C2          | P1         | 500    | completed
-- 5      | C2          | P3         | 400    | completed
-- 6      | C3          | P1         | 500    | completed
-- 7      | C3          | P2         | 300    | completed
-- 8      | C3          | P2         | 300    | cancelled
-- 9      | C4          | P3         | 400    | completed
-- 10     | C4          | P3         | 400    | cancelled

-- Q1. What is exact output of a, b, c?
-- SELECT
--   COUNT(customer_id)          AS a,
--   COUNT(DISTINCT customer_id) AS b,
--   COUNT(DISTINCT product_id)  AS c
-- FROM transactions;

-- Q2. What is wrong with this?
-- SELECT SUM(DISTINCT amount) AS total FROM transactions;
-- Hint: What amounts get deduplicated?
--       What is real total vs DISTINCT total?

-- Q3. Write query per category:
--   total transactions, unique customers,
--   unique products, total revenue
-- Hint: COUNT(DISTINCT) for unique!

-- Q4. What is difference between:
-- COUNT(DISTINCT customer_id, product_id)
-- vs
-- COUNT(DISTINCT customer_id) * COUNT(DISTINCT product_id)
-- Hint: Actual combinations vs assumed combinations!

-- =============================================
-- TOPIC 10: AGGREGATION ON DERIVED COLUMNS
-- =============================================

-- Dataset:
-- sales table
-- sale_id | rep_id | amount | discount_pct | tax_pct
-- --------|--------|--------|--------------|--------
-- 1       | R1     | 1000   | 10           | 18
-- 2       | R1     | 2000   | 20           | 18
-- 3       | R2     | 1500   | 15           | 12
-- 4       | R2     | 500    | 5            | 12
-- 5       | R3     | 3000   | 25           | 18
-- 6       | R3     | 800    | 10           | 12

-- Formulas:
-- After discount = amount * (1 - discount_pct/100)
-- After tax      = discounted * (1 + tax_pct/100)
-- Combined       = amount * (1-disc/100) * (1+tax/100)

-- Q1. Write query per rep:
--   total amount, total after discount,
--   total after tax, average net amount
-- Hint: Use CTE to calculate derived columns first!

-- Q2. What is wrong with this?
-- SELECT rep_id,
--   amount * (1 - discount_pct/100) AS discounted,
--   SUM(discounted) AS total_discounted
-- FROM sales GROUP BY rep_id;
-- Hint: Can you use SELECT alias in same SELECT?

-- Q3. Write query: reps with net revenue after
--   discount and tax > 2000
-- Hint: HAVING with full expression!
--       Or CTE then WHERE!

-- Q4. Can you use SELECT alias in HAVING?
-- HAVING total_discounted > 2000
-- Hint: SQL execution order!

-- =============================================
-- TOPIC 11: ROLLUP & CUBE
-- =============================================

-- Dataset:
-- sales table
-- sale_id | region | category    | amount
-- --------|--------|-------------|-------
-- 1       | North  | Electronics | 500
-- 2       | North  | Clothing    | 300
-- 3       | South  | Electronics | 700
-- 4       | South  | Clothing    | 400
-- 5       | North  | Electronics | 600

-- Q1. How many rows will this return?
-- SELECT region, category, SUM(amount)
-- FROM sales
-- GROUP BY ROLLUP(region, category);
-- Hint: Individual + subtotals + grand total!

-- Q2. What is difference between ROLLUP and CUBE
--   on single column?
-- Hint: Same result! Why?

-- Q3. What is difference between ROLLUP and CUBE
--   on two columns?
-- Hint: ROLLUP = hierarchical, CUBE = all combinations!

-- Q4. How do you distinguish ROLLUP NULL
--   from actual NULL values?
-- Hint: GROUPING() function!

-- =============================================
-- TOPIC 12: DUPLICATE HANDLING
-- =============================================

-- Dataset:
-- orders table
-- order_id | customer_id | product_id | amount | status    | created_at
-- ---------|-------------|------------|--------|-----------|---------------------
-- 1        | C1          | P1         | 500    | pending   | 2023-01-10 08:00:00
-- 2        | C1          | P1         | 500    | completed | 2023-01-10 09:00:00
-- 3        | C1          | P2         | 300    | completed | 2023-01-11 10:00:00
-- 4        | C2          | P1         | 500    | pending   | 2023-01-10 08:00:00
-- 5        | C2          | P1         | 500    | pending   | 2023-01-10 08:00:00
-- 6        | C2          | P3         | 700    | completed | 2023-01-12 11:00:00
-- 7        | C3          | P2         | 300    | completed | 2023-01-11 10:00:00
-- 8        | C3          | P2         | 300    | completed | 2023-01-11 10:00:00

-- Q1. Write query to find exact duplicates
-- Hint: GROUP BY all columns + HAVING COUNT(*) > 1

-- Q2. Write query to keep only latest record
--   per customer + product combination
-- Hint: ROW_NUMBER() PARTITION BY business key!
--       ORDER BY created_at DESC!

-- Q3. Write query to delete duplicates
--   keeping lowest order_id
-- Hint: NOT IN + MIN(order_id) subquery!

-- Q4. Write pipeline deduplication query
--   Insert only non-duplicate records from staging
-- Hint: NOT EXISTS or MERGE statement!

-- =============================================
-- TOPIC 13: GROUP BY DEEP PRACTICE
-- =============================================

-- PROBLEM 1:
-- Dataset: employee_performance
-- emp_id | name | dept | region | salary | rating | joined_year

-- Write single query per dept + region:
-- total employees, avg salary (NULL safe),
-- count rating 5, count rating 4+,
-- max salary, min salary, salary range,
-- % rating 5 employees,
-- label: Star Team/Good Team/Needs Work
-- Only groups with at least 2 employees
-- Hint: Multiple CASE WHEN + HAVING!

-- PROBLEM 2:
-- Dataset: customers + orders tables
-- Write single query per city + segment:
-- total customers, total orders, total revenue,
-- avg order value, completed revenue,
-- cancellation rate %, most ordered category,
-- activity label (High/Low based on avg orders)
-- Only groups with total revenue > 500
-- Hint: CTE for complex calculations!

-- PROBLEM 3:
-- Dataset: transactions table
-- Write query per customer:
-- total transactions, total amount,
-- completed/cancelled amounts,
-- unique products, unique categories,
-- first/last transaction date,
-- days between first and last,
-- most purchased category,
-- customer value segment (Champion/Loyal/At Risk)
-- Only customers with at least 2 completed transactions
-- Hint: MIN/MAX for dates, RANK for category!

-- PROBLEM 4:
-- Dataset: sales_data table
-- Write query per salesperson + quarter:
-- total sales, units, avg sale amount,
-- avg revenue per unit (NULLIF!),
-- Electronics/Clothing revenue,
-- Electronics % of total,
-- best performing region,
-- QoQ growth label,
-- performance label
-- Only combos with at least 2 transactions
-- Hint: Multiple CTEs for complex logic!

-- PROBLEM 5:
-- Dataset: hospital_data table
-- Write query per department + doctor:
-- total patients, unique patients,
-- total/avg treatment cost,
-- completed revenue, cancelled count,
-- cancellation rate %,
-- most common diagnosis (handle ties!),
-- cost efficiency label,
-- doctor performance label
-- Only combos with at least 2 visits
-- Hint: RANK() for ties in diagnosis!

-- PROBLEM 6:
-- Dataset: ecommerce_data table
-- Write query per seller + category:
-- total orders, unique customers,
-- net revenue (amount - discount + tax),
-- avg net revenue per order,
-- delivered/cancelled counts,
-- cancellation rate %,
-- avg delivery days (delivered only!),
-- total units, revenue per unit,
-- discount impact %,
-- category performance label
-- Only combos with at least 2 orders
-- Hint: NULLIF for safe division!
--       delivery_date - order_date for days!
