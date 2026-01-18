#null过滤
SELECT first_name, last_name
FROM employees
WHERE manager_id IS NULL;

#employee-manager self join
SELECT
  e.first_name AS employee_first,
  e.last_name  AS employee_last,
  m.first_name AS manager_first,
  m.last_name  AS manager_last
FROM employees e
LEFT JOIN employees m
  ON e.manager_id = m.emp_id;

-- Day2 (1/15): filter with AND
SELECT product_id
FROM products
WHERE low_fats = 'Y'
  AND recyclable = 'Y';

-- Day3 (1/16) Top-N per group

/* Top N per group */
ROW_NUMBER() OVER (PARTITION BY grp_col ORDER BY metric_col DESC) AS rn

/* Dedupe keep latest */
ROW_NUMBER() OVER (PARTITION BY key_col ORDER BY ts_col DESC) AS rn

/* Running total */
SUM(x) OVER (PARTITION BY grp_col ORDER BY dt_col
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum

