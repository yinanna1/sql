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
-- day5
/*WHERE VS HAVING
	WHERE filters rows BEFORE grouping
	HAVING filters AFTER grouping
*/

SELECT customer_id, COUNT(*) AS order_cnt
FROM orders
GROUP BY customer_id
HAVING COUNT(*) >= 2;

/*Anti-join: “A but not in B” (no matching rows)
LEFT JOIN + IS NULL*/
SELECT c.*
FROM customers c
LEFT JOIN orders o
  ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;   -- use a NOT-NULL column from o (usually PK)

/*3) NULL handling essentials*/
-- COUNT(*) vs COUNT(col)
SELECT
  COUNT(*) AS total_rows,
  COUNT(amount) AS non_null_amount_rows,
  SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS null_amount_rows
FROM orders;

-- COALESCE for default values
SELECT SUM(COALESCE(amount, 0)) AS total_amount
FROM orders;

-- safe division
SELECT 1.0 * num / NULLIF(den, 0) AS rate;

/*RANK vs DENSE_RANK vs ROW_NUMBER (ties behavior)*/
-- ties: RANK (1,1,3) / DENSE_RANK (1,1,2) / ROW_NUMBER (1,2,3)
RANK()       OVER (PARTITION BY grp ORDER BY metric DESC) AS rnk
DENSE_RANK() OVER (PARTITION BY grp ORDER BY metric DESC) AS drnk
ROW_NUMBER() OVER (PARTITION BY grp ORDER BY metric DESC) AS rn

/*LAG/LEAD (diff vs previous/next)*/
SELECT
  t.*,
  LAG(value_col)  OVER (PARTITION BY key_col ORDER BY dt_col) AS prev_val,
  value_col - LAG(value_col) OVER (PARTITION BY key_col ORDER BY dt_col) AS diff_prev
FROM your_table t;

/*Moving average (rows-based)*/
AVG(x) OVER (
  PARTITION BY grp_col
  ORDER BY dt_col
  ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
) AS ma7

/*Percent of total (per group)*/
SELECT
  t.*,
  1.0 * amount / SUM(amount) OVER (PARTITION BY grp_col) AS pct_of_group
FROM your_table t;

/*Consecutive days*/
WITH d AS (
  SELECT DISTINCT key_col, DATE(dt_col) AS dt
  FROM your_table
),
x AS (
  SELECT
    key_col,
    dt,
    DATE_SUB(
      dt,
      INTERVAL ROW_NUMBER() OVER (PARTITION BY key_col ORDER BY dt) DAY
    ) AS grp
  FROM d
),
runs AS (
  SELECT
    key_col,
    grp,
    COUNT(*) AS len,
    MIN(dt) AS start_day,
    MAX(dt) AS end_day
  FROM x
  GROUP BY key_col, grp
)
SELECT *
FROM runs
WHERE len >= 3;  -- k consecutive days

/*MoM / YoY*/
WITH monthly AS (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m-01') AS month_start,
    SUM(amount) AS month_sales
  FROM orders
  GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
)
SELECT
  month_start,
  month_sales,
  month_sales - LAG(month_sales) OVER (ORDER BY month_start) AS mom_diff,
  (month_sales - LAG(month_sales) OVER (ORDER BY month_start))
    / NULLIF(LAG(month_sales) OVER (ORDER BY month_start), 0) AS mom_pct
FROM monthly
ORDER BY month_start;

/*JOIN pitfall: LEFT JOIN accidentally becomes INNER*/
SELECT *
FROM A
LEFT JOIN B
  ON B.a_id = A.id
 AND B.status = 'ok';

/*Latest per group”*/
WITH x AS (
  SELECT
    e.*,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY event_time DESC, event_id DESC
    ) AS rn
  FROM events e
)
SELECT *
FROM x
WHERE rn = 1;

/*Distinct counting*/
-- count unique users per day
SELECT
  order_date,
  COUNT(DISTINCT user_id) AS users
FROM orders
GROUP BY order_date;



