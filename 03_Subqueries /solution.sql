_______________________________________________________________________________
_______________________________________________________________________________
Question 1 of 13
Scalar Subqueries
_______________________________________________________________________________
Answers

A1:
SELECT
name,
salary,
  (SELECT AVG(salary) FROM employees)
    AS avg_company_sal,
  salary - (SELECT AVG(salary) FROM employees)
    AS diff_from_avg
FROM employees
GROUP BY emp_id;

A2:
/* Once using subquery in WHERE */

SELECT
name
FROM employees
WHERE salary>(SELECT AVG(salary) FROM employees);

/* Once using CTE */
WITH company_avg AS (
  SELECT AVG(salary) AS avg_salary
  FROM employees
)
SELECT name, salary
FROM employees
WHERE salary > (SELECT avg_salary FROM company_avg);
A3:

In Query A, we are fetching the employee name and salary from employees tables where employee salary is greater than company avgerage salary.
Whereas in query B, we are focusing to fetch the employee name and salary whose salary is greater than  only on Tech department

A4:
AVG can handle the Null value by itself as AVG() may face Null trap here
so the alternative to handle this NUll is

SELECT
name
FROM employees
WHERE salary>(SELECT AVG(COALESCE(salary, 0)) as Avg_sal FROM employees);

_____________________________________________________________________________________
