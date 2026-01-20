USE interview_practice;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;

CREATE TABLE orders (
  order_id   INT PRIMARY KEY,
  user_id    INT,
  order_date DATE,
  status     VARCHAR(20),  -- completed/canceled/refunded
  channel    VARCHAR(20)   -- app/web
);

CREATE TABLE order_items (
  order_id   INT,
  product_id INT,
  qty        INT,
  unit_price DECIMAL(10,2)
);

CREATE TABLE products (
  product_id INT PRIMARY KEY,
  category   VARCHAR(20)
);

INSERT INTO products (product_id, category) VALUES
(101,'snack'),(102,'snack'),(103,'drink'),(104,'drink'),
(105,'daily'),(106,'daily'),(107,'snack'),(108,'daily');

INSERT INTO orders (order_id, user_id, order_date, status, channel) VALUES
(1, 1,'2026-01-10','completed','app'),
(2, 1,'2026-01-11','canceled','web'),
(3, 2,'2026-01-11','completed','web'),
(4, 2,'2026-01-12','refunded','app'),
(5, 3,'2026-01-12','completed','app'),
(6, 3,'2026-01-13','completed','web'),
(7, 4,'2026-01-13','canceled','app'),
(8, 4,'2026-01-14','completed','web'),
(9, 5,'2026-01-14','completed','app'),
(10,5,'2026-01-15','completed','web'),
(11,2,'2026-01-15','canceled','web'),
(12,1,'2026-01-15','completed','app');

INSERT INTO order_items (order_id, product_id, qty, unit_price) VALUES
(1,101,2,3.00),(1,103,1,2.50),
(2,102,1,3.50),
(3,104,2,2.00),
(4,105,1,10.00),
(5,101,1,3.00),(5,106,2,4.00),
(6,107,3,2.00),
(7,108,1,6.00),
(8,103,2,2.50),(8,105,1,10.00),
(9,101,5,3.00),
(10,104,1,2.00),(10,106,1,4.00),
(11,102,2,3.50),
(12,105,1,10.00),(12,107,2,2.00);

/*Q1
Q1（基础聚合）
按 user_id 统计：总订单数、完成订单数、取消订单数、退款订单数（用条件聚合）。
*/

SELECT 
	user_id,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'completed' Then 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(CASE WHEN status = 'refunded' THEN 1 ELSE 0 END) AS refunded_orders
FROM orders
GROUP BY user_id
ORDER BY user_id;

/*Q2
Q2（金额聚合）
每个 user_id 的总消费额（只算 status='completed' 的订单）。
金额来自 order_items.qty * unit_price，注意要 join。
*/

SELECT 
	o.user_id,
    ROUND(SUM(oi.qty * oi.unit_price),2) AS total_spend
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY o.user_id
ORDER BY o.user_id;

/*Q3
Q3（HAVING）
找出完成订单数 ≥ 2 的用户（user_id 列表即可）。
*/

SELECT
	user_id
FROM orders
GROUP BY user_id
HAVING SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) >= 2
ORDER BY user_id;
    
/*
Q4（按天统计 + 比例）
按 order_date 统计：
当天总订单数
当天完成订单数
完成率 = 完成订单数 / 总订单数（保留 2 位小数）
*/

SELECT
	order_date,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_orders,
    ROUND(SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END)/COUNT(*),2) AS completion_rate
FROM orders
GROUP BY order_date
ORDER BY order_date;

/*
Q5（分渠道表现）
按 channel 统计：
总订单数
完成订单数
退款订单数
退款率 = 退款订单数 / 总订单数

*/

SELECT
	channel,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN status = 'refunded' THEN 1 ELSE 0 END) AS refunded_orders,
    ROUND(SUM(CASE WHEN status = 'refunded' THEN 1 ELSE 0 END)/ COUNT(*),2) AS refunded_rate
FROM orders
GROUP BY channel
ORDER BY channel;

/*
Q6（类目营收）
按 products.category 统计：
完成订单的营收（sum(qty*price)）
卖出件数（sum(qty)）
只算 completed。
*/
USE interview_practice;
SELECT
	p.category,
    ROUND(SUM(oi.qty * oi.unit_price),2) AS revenue,
    SUM(oi.qty) AS units_sold
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN products p
	ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY p.category;

/*
Q7（去重统计）
按 category 统计：购买该类目的不同用户数（distinct buyers）。
注意：一个用户可能买同类目多次，只算 1。
*/

SELECT
	p.category,
    COUNT(DISTINCT o.user_id) AS distinct_buyers
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN products p
	ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY p.category;

/*
Q8（Bonus：Top1 per group）
每个 category 找出营收最高的 product_id（只算 completed）。
你可以用 ROW_NUMBER()（你之前学过 top-N per group）。
*/
USE interview_practice;
WITH prod_rev AS(
	SELECT
		p.category,
        oi.product_id,
        SUM(oi.qty * oi.unit_price) AS revenue
	FROM orders o 
    JOIN order_items oi
		ON o.order_id = oi.order_id
	JOIN products p
		ON oi.product_id = p.product_id
	WHERE o.status = 'completed'
    GROUP BY p.category, oi.product_id
),
ranked AS(
	SELECT
		category,
        product_id,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC, product_id) AS rn
	FROM prod_rev
)
SELECT 
	category,
    product_id,
    ROUND(revenue,2) AS revenue
FROM ranked
WHERE rn = 1
ORDER BY category;