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

-- T1: Conditional Aggregation
SELECT
  user_id,
  COUNT(*) AS total_cnt,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_cnt,
  SUM(CASE WHEN status = 'canceled'  THEN 1 ELSE 0 END) AS canceled_cnt,
  1.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS completed_rate
FROM orders
GROUP BY user_id;

-- T2: CTE -> agg -> window (TopN per period)
WITH monthly AS (
  SELECT
    user_id,
    DATE_FORMAT(order_date, '%Y-%m') AS ym,
    SUM(amount) AS revenue
  FROM orders
  GROUP BY user_id, DATE_FORMAT(order_date, '%Y-%m')
)
SELECT *
FROM (
  SELECT
    ym, user_id, revenue,
    DENSE_RANK() OVER (PARTITION BY ym ORDER BY revenue DESC) AS rnk
  FROM monthly
) t
WHERE rnk <= 3;

-- T3: Latest per group (correlated subquery)
SELECT t1.*
FROM events t1
WHERE t1.event_time = (
  SELECT MAX(t2.event_time)
  FROM events t2
  WHERE t2.user_id = t1.user_id
);


