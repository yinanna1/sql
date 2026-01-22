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

-- Day4 (1/19) ADD-ON templates (NEW only)

/* A) Conditional DISTINCT count (条件 + 去重 统计) */
SELECT
  DATE(order_date) AS dt,
  COUNT(DISTINCT CASE WHEN status = 'completed' THEN user_id END) AS completed_users,
  COUNT(DISTINCT CASE WHEN status = 'canceled'  THEN user_id END) AS canceled_users
FROM orders
GROUP BY DATE(order_date);

/* B) Pivot-style aggregation (把行“横”成列：按渠道拆列) */
SELECT
  user_id,
  SUM(CASE WHEN channel = 'app' THEN amount ELSE 0 END) AS revenue_app,
  SUM(CASE WHEN channel = 'web' THEN amount ELSE 0 END) AS revenue_web
FROM orders
GROUP BY user_id;

/* C) Ratio filter with HAVING (用比例筛分组) */
SELECT
  user_id,
  COUNT(*) AS total_cnt,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_cnt,
  1.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS completed_rate
FROM orders
GROUP BY user_id
HAVING 1.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) >= 0.7;

/* D) COUNT DISTINCT on multiple columns (多列去重计数：MySQL 支持) */
SELECT
  COUNT(DISTINCT user_id, order_date) AS unique_user_days
FROM orders;

/* E) Weighted average (加权平均) */
SELECT
  grp_col,
  1.0 * SUM(value_col * weight_col) / NULLIF(SUM(weight_col), 0) AS weighted_avg
FROM your_table
GROUP BY grp_col;

/* F) Subtotals / Grand total (ROLLUP：小计 + 总计) */
SELECT
  channel,
  status,
  SUM(amount) AS revenue
FROM orders
GROUP BY channel, status WITH ROLLUP;

-- DAY 7(1/21)
/*1) Order-level amount（先把明细变成订单金额，防止 join 放大）*/
/* Order amount from order_items */
WITH order_amount AS (
  SELECT
    order_id,
    SUM(qty * unit_price) AS amount
  FROM order_items
  GROUP BY order_id
)

/*LEFT JOIN 保留所有用户（右表过滤条件放 ON + COALESCE）*/
/* Keep all users even if no completed orders */
WITH order_amount AS (
  SELECT order_id, SUM(qty * unit_price) AS amount
  FROM order_items
  GROUP BY order_id
)
SELECT
  u.user_id,
  COUNT(o.order_id) AS completed_order_cnt,      -- COUNT(col) ignores NULL
  COALESCE(SUM(oa.amount), 0) AS completed_spend -- SUM could be NULL -> 0
FROM users u
LEFT JOIN orders o
  ON u.user_id = o.user_id
 AND o.status = 'completed'   -- IMPORTANT: filter on ON, not WHERE
LEFT JOIN order_amount oa
  ON o.order_id = oa.order_id
GROUP BY u.user_id;

/*LEFT JOIN + 右表条件放 WHERE 会把 NULL 行过滤掉 → 变相 INNER JOIN*/

/*3) “按维度汇总收入”通用模板（channel/category 都能套*/
/* Revenue by dimension (e.g., channel / category) */
WITH order_amount AS (
  SELECT order_id, SUM(qty * unit_price) AS amount
  FROM order_items
  GROUP BY order_id
)
SELECT
  o.channel,                 -- 换成你要的维度
  COUNT(*) AS completed_cnt,
  SUM(oa.amount) AS revenue,
  AVG(oa.amount) AS aov
FROM orders o
JOIN order_amount oa ON o.order_id = oa.order_id
WHERE o.status = 'completed'
GROUP BY o.channel;

/*4) COUNT DISTINCT + HAVING（买过 ≥2 类 / 达到门槛）*/

/* Users who bought >= N distinct categories (completed only) */
SELECT
  o.user_id,
  COUNT(DISTINCT p.category) AS distinct_category_cnt,
  SUM(oi.qty * oi.unit_price) AS spend
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY o.user_id
HAVING COUNT(DISTINCT p.category) >= 2;

/*Top N products per category by revenue（CTE算 sales + window 排名）*/

/* Top N products per category by revenue (completed only) */
WITH product_sales AS (
  SELECT
    p.category,
    oi.product_id,
    SUM(oi.qty * oi.unit_price) AS revenue
  FROM order_items oi
  JOIN products p ON oi.product_id = p.product_id
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY p.category, oi.product_id
),
ranked AS (
  SELECT
    category,
    product_id,
    revenue,
    ROW_NUMBER() OVER (
      PARTITION BY category
      ORDER BY revenue DESC, product_id ASC
    ) AS rn
  FROM product_sales
)
SELECT category, product_id, revenue
FROM ranked
WHERE rn <= 2;

/*6) Latest completed order per user（结合 order_amount + ROW_NUMBER）
*/

/* Latest completed order per user */
WITH order_amount AS (
  SELECT order_id, SUM(qty * unit_price) AS amount
  FROM order_items
  GROUP BY order_id
),
ranked AS (
  SELECT
    o.user_id, o.order_id, o.order_date, oa.amount,
    ROW_NUMBER() OVER (
      PARTITION BY o.user_id
      ORDER BY o.order_date DESC, o.order_id DESC
    ) AS rn
  FROM orders o
  JOIN order_amount oa ON o.order_id = oa.order_id
  WHERE o.status = 'completed'
)
SELECT user_id, order_id, order_date, amount
FROM ranked
WHERE rn = 1;
