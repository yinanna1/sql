/* Sprint 1: JOIN + GROUP BY
Goal: 每个 customer 的 total_spend（总花费），并按总花费降序
*/

WITH customers AS (
  SELECT 1 AS customer_id, 'Amy' AS name UNION ALL
  SELECT 2, 'Ben' UNION ALL
  SELECT 3, 'Cindy'
),
orders AS (
  SELECT 101 AS order_id, 1 AS customer_id, 40 AS amount UNION ALL
  SELECT 102, 1, 15 UNION ALL
  SELECT 103, 2, 22 UNION ALL
  SELECT 104, 2, 18 UNION ALL
  SELECT 105, 3, 60
)
-- TODO: write your query below
SELECT 
	c.customer_id,
    c.name,
    SUM(o.amount) AS total_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spend DESC;

/* Sprint 2: Dedupe keep latest
Goal: 每个 user 只保留最新一条记录


WITH events AS (
  SELECT 1 AS user_id, '2026-01-15 10:00:00' AS ts, 'login'  AS action UNION ALL
  SELECT 1,            '2026-01-15 10:05:00',      'view'           UNION ALL
  SELECT 2,            '2026-01-15 09:59:00',      'login'          UNION ALL
  SELECT 2,            '2026-01-15 10:20:00',      'logout'         UNION ALL
  SELECT 3,            '2026-01-15 08:00:00',      'login'
)
-- TODO: write your query below (hint: ROW_NUMBER)
ranked AS(
	SELECT
    e.*,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY ts DESC) AS rn
    FROM events e
    )
SELECT user_id, ts, action
FROM ranked
WHERE rn = 1
ORDER BY user_id;
*/
/*
Sprint 3: Top-N per group
Goal: 每个部门工资 top 2


WITH employees AS (
  SELECT 1 AS emp_id, 'A' AS dept, 120 AS salary UNION ALL
  SELECT 2,          'A',           115 UNION ALL
  SELECT 3,          'A',           115 UNION ALL
  SELECT 4,          'B',           130 UNION ALL
  SELECT 5,          'B',           90  UNION ALL
  SELECT 6,          'B',           88
),
-- TODO: write your query below
ranked AS(
SELECT e.*,
	ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY salary ASC) AS rn
    FROM employees e
	)
SELECT *
FROM ranked
where rn <=2
ORDER BY dept, rn;
*/
/* Sprint 4: Running total
Goal: 每个 user 按日期做累计消费 running_sum
*/

WITH payments AS (
  SELECT 1 AS user_id, '2026-01-14' AS dt, 10 AS amount UNION ALL
  SELECT 1,            '2026-01-15',        20 UNION ALL
  SELECT 1,            '2026-01-16',        5  UNION ALL
  SELECT 2,            '2026-01-15',        7  UNION ALL
  SELECT 2,            '2026-01-16',        9
)
-- TODO: write your query below
SELECT
  p.*,
  SUM(amount) OVER (
    PARTITION BY user_id
    ORDER BY dt
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_sum
FROM payments p
ORDER BY user_id, dt;
