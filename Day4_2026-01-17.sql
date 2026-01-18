USE interview_practice;
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  status VARCHAR(20) NOT NULL,
  order_date DATE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  INDEX idx_orders_user_date (user_id, order_date),
  INDEX idx_orders_date (order_date)
);

DROP TABLE IF EXISTS events;
CREATE TABLE events (
  event_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  event_time DATETIME NOT NULL,
  event_type VARCHAR(50),
  INDEX idx_events_user_time (user_id, event_time)
);

DROP TABLE IF EXISTS user_profile;
CREATE TABLE user_profile (
  profile_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  updated_at DATETIME NOT NULL,
  name VARCHAR(100),
  email VARCHAR(255),
  INDEX idx_profile_user_updated (user_id, updated_at)
);

-- 插一点样例数据（保证题1-6都能跑出结果）
INSERT INTO orders (user_id, status, order_date, amount) VALUES
(1,'completed','2025-01-05',20.00),
(1,'canceled' ,'2025-01-06',15.00),
(1,'completed','2025-02-10',50.00),
(2,'completed','2025-01-15',30.00),
(2,'completed','2025-02-20',40.00),
(2,'completed','2025-02-21',10.00),
(3,'canceled' ,'2025-01-02',25.00),
(3,'completed','2025-03-01',60.00);

INSERT INTO events (user_id, event_time, event_type) VALUES
(1,'2025-01-01 10:00:00','login'),
(1,'2025-01-02 10:00:00','login'),
(1,'2025-01-04 10:00:00','login'),
(1,'2025-01-05 10:00:00','purchase'),
(2,'2025-01-01 09:00:00','login'),
(2,'2025-01-02 09:00:00','login'),
(2,'2025-01-03 09:00:00','login'),
(2,'2025-01-10 09:00:00','login'),
(3,'2025-02-01 08:00:00','login'),
(3,'2025-02-03 08:00:00','login');

INSERT INTO user_profile (user_id, updated_at, name, email) VALUES
(1,'2025-01-01 00:00:00','A','a@test.com'),
(1,'2025-02-01 00:00:00','A2','a2@test.com'),
(2,'2025-01-15 00:00:00','B','b@test.com'),
(2,'2025-01-20 00:00:00','B2','b2@test.com'),
(3,'2025-03-01 00:00:00','C','c@test.com');

/*题 1：Conditional Aggregation（最常考）

按用户统计：总订单数、已完成数、取消数、完成率
关键词：COUNT(*) + SUM(CASE WHEN ...) + 注意除法/NULL
*/

SELECT
	user_id,
	COUNT(*) AS total_cnt,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_cnt,
    SUM(CASE WHEN status = 'canceled' THEN 1 ELSE 0 END) AS canceled_cnt,
    1.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END)/ NULLIF(COUNT(*), 0) AS completed_rate
From orders
GROUP BY user_id;
    


/*题 2：CTE 分步聚合（面试喜欢看结构化思路）

先算每个 user 每月消费，再算每月 Top 3 用户
关键词：WITH monthly AS (...) + DENSE_RANK() OVER(PARTITION BY month ORDER BY revenue DESC)


WITH monthly AS(
	SELECT
		user_id,
        DATE_FORMAT(order_date, '%Y-%m') AS ym,
        SUM(amount) AS revenue
	FROM orders
    GROUP BY user_id, DATE_FORMAT(order_date, '%Y-%m')
),
ranked AS(
	SELECT
		ym, 
		user_id,
		revenue,
		DENSE_RANK() OVER (PARTITION BY ym ORDER BY revenue DESC) AS rnk
    FROM monthly
)
SELECT
	ym, user_id, revenue, rnk
FROM ranked
WHERE rnk <=3
ORDER BY ym, rnk, user_id;
*/

/*
题 3：Correlated Subquery（不用窗口也能做“每组最新”）

找每个 user 的最新一条事件（按时间最大）
关键词：WHERE created_at = (SELECT MAX(...) FROM t2 WHERE t2.user_id = t1.user_id)

--#1
SELECT e1.*
FROM events e1
WHERE e1.event_time = (
  SELECT MAX(e2.event_time)
  FROM events e2
  WHERE e2.user_id = e1.user_id
);
--#2
WITH ranked AS(
	SELECT
		e.*,
		ROW_NUMBER() OVER(
			PARTITION BY user_id
			ORDER BY event_time DESC, event_id DESC
		) AS rn
	FROM events e
)
SELECT *
FROM ranked
WHERE rn = 1;
*/
/*题 4：Date/Time + Trend（MoM / WoW）

按月算 GMV，并算 MoM 增长率
关键词：DATE_FORMAT()/EXTRACT()（按你 MySQL 方言）+ LAG() + 注意第一行 MoM 为 NULL

USE interview_practice;
WITH m AS(
	SELECT
		DATE_FORMAT(order_date, '%Y-%m') AS ym,
		SUM(amount) AS gmv
	FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
calc AS(
	SELECT
		ym,
        gmv,
        LAG(gmv) OVER (ORDER BY ym) AS prev_gmv
	FROM m
)
SELECT
	ym,
    gmv,
    prev_gmv,
    (gmv-prev_gmv) / NULLIF(prev_gmv, 0) AS mom_growth
From calc
ORDER BY ym;
*/
/*题 5：去重保留最新（窗口函数 + CTE 组合）

同一 user 可能多条 profile 记录，只保留最新一条
关键词：ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY updated_at DESC) 然后 WHERE rn=1

USE interview_practice;

WITH ranked AS(
	SELECT
		p.*,
        ROW_NUMBER() OVER(
			PARTITION BY user_id
            ORDER BY updated_at DESC, profile_id DESC
		) AS rn
	FROM user_profile p
)
SELECT
	profile_id, user_id, updated_at, name, email
FROM ranked
WHERE rn = 1
ORDER BY user_id;
*/

/*题 6：连续登录/连续天数（加分题）

找每个 user 的最长连续活跃天数（不会也没关系，但你做出来会很强）
关键词：ROW_NUMBER() + date - rn 分组套路（如果卡住就先写思路进 wrongbook）
*/
USE interview_practice;

WITH d AS(
	SELECT DISTINCT
		user_id, DATE(event_time) AS day
	FROM events
),
r AS(
	SELECT
		user_id, day,
        ROW_NUMBER() OVER( PARTITION BY user_id ORDER BY day) AS rn
	FROM d
),
grp AS(
	SELECT
		user_id, day,
        DATE_SUB(day, INTERVAL rn DAY) AS grp_key
	FROM r
),
streaks AS(
	SELECT
		user_id, grp_key,
        COUNT(*) AS streak_len,
        MIN(day) AS start_day,
        MAX(day) AS end_day
	FROM grp
    GROUP BY user_id, grp_key
),
best AS(
	SELECT
		s.*,
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY streak_len DESC, end_day DESC) AS rn
	FROM streaks s
)
SELECT
	user_id, streak_len, start_day, end_day
FROM best
WHERE rn = 1
ORDER BY streak_len DESC, user_id;