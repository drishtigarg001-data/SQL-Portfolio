# Subqueries
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
____________________________________________________________________________________
____________________________________________________________________________________
Subqueries — Question 1 of 13
Scalar Subqueries — foundation of everything!
____________________________________________________________________________________
____________________________________________________________________________________
-- employees table
emp_id | name      | dept       | salary | join_year
-------|-----------|------------|--------|----------
1      | Alice     | Tech       | 80000  | 2019
2      | Bob       | Tech       | 60000  | 2020
3      | Charlie   | Tech       | 90000  | 2018
4      | David     | HR         | 50000  | 2021
5      | Eve       | HR         | 70000  | 2019
6      | Frank     | Finance    | 85000  | 2020
7      | Grace     | Finance    | 95000  | 2018
8      | Henry     | Finance    | 75000  | 2021
9      | Ivan      | Tech       | NULL   | 2022
10     | Julia     | HR         | 55000  | 2020
____________________________________________________________________________________

Questions:

Write a query to show each employee with:
Their salary
Company wide average salary
Difference from company average

2. Write a query to find employees who earn more than company average
Once using subquery in WHERE
Once using CTE

3. What is the difference between these two?

sql-- Query A
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Query B
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary)
                FROM employees
                WHERE dept = 'Tech');

4. What happens to Ivan (NULL salary) in all queries — trace through carefully.
_____________________________________________________________________________________
_____________________________________________________________________________________

Subqueries — Question 2 of 13
Correlated Subqueries
_____________________________________________________________________________________
-- employees table
emp_id | name    | dept    | salary | manager_id
-------|---------|---------|--------|------------
1      | Alice   | Tech    | 80000  | 3
2      | Bob     | Tech    | 60000  | 3
3      | Charlie | Tech    | 90000  | NULL
4      | David   | HR      | 50000  | 6
5      | Eve     | HR      | 70000  | 6
6      | Frank   | HR      | 85000  | NULL
7      | Grace   | Finance | 95000  | NULL
8      | Henry   | Finance | 75000  | 7
9      | Ivan    | Finance | 80000  | 7
10     | Julia   | Tech    | 55000  | 3
___________________________________________________________________________________
Questions:

1. Write a query to find employees who earn more than their department average using correlated subquery
2. Write a query to find employees who earn more than their manager using correlated subquery
3. What is the difference between these two?
sql
-- Query A (Non-Correlated)
SELECT name FROM employees
WHERE salary > (
  SELECT AVG(salary) FROM employees
);

-- Query B (Correlated)
SELECT name FROM employees e1
WHERE salary > (
  SELECT AVG(salary) FROM employees e2
  WHERE e2.dept = e1.dept
);
Explain execution difference — kitni baar inner query chalti hai?

4. What is the performance problem with correlated subqueries and when would you still use them?

___________________________________________________________________________________
