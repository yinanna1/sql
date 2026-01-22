-- Minimal practice database (JOIN + GROUP BY)
DROP DATABASE IF EXISTS interview_practice;
CREATE DATABASE interview_practice;
USE interview_practice;

-- Drop tables (in FK-safe order even though we don't use FKs)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;

-- users (needed for LEFT JOIN / show users with 0 orders)
CREATE TABLE users (
  user_id INT PRIMARY KEY
);

-- products
CREATE TABLE products (
  product_id INT PRIMARY KEY,
  category   VARCHAR(20)
);

-- orders
CREATE TABLE orders (
  order_id   INT PRIMARY KEY,
  user_id    INT,
  order_date DATE,
  status     VARCHAR(20),  -- completed/canceled/refunded
  channel    VARCHAR(20)   -- app/web
);

-- order_items
CREATE TABLE order_items (
  order_id   INT,
  product_id INT,
  qty        INT,
  unit_price DECIMAL(10,2)
);

-- Seed: users (include 6 = no orders, so LEFT JOIN tests are meaningful)
INSERT INTO users (user_id) VALUES
(1),(2),(3),(4),(5),(6);

-- Seed: products
INSERT INTO products (product_id, category) VALUES
(101,'snack'),(102,'snack'),(103,'drink'),(104,'drink'),
(105,'daily'),(106,'daily'),(107,'snack'),(108,'daily');

-- Seed: orders
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

-- Seed: order_items
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

/*
题 1（LEFT JOIN + 聚合）

**需求：**列出所有用户（含没下单的 user 6），统计

completed 订单数

completed 总消费（qty * unit_price 汇总）
*/
USE interview_practice;
WITH order_amount AS(
	SELECT
		order_id,
		SUM(qty * unit_price) AS amount
	FROM order_items
    GROUP BY order_id
)
SELECT
	u.user_id,
    COUNT(o.order_id) AS completed_order_cnt,
    COALESCE(SUM(oa.amount),0) AS completed_total_spend
FROM users u
LEFT JOIN orders o
	ON u.user_id = o.user_id
    AND o.status = 'completed'
    
/*The LEFT JOIN keyword returns all records from the left table (table1), 
and the matching records from the right table (table2)
*/
LEFT JOIN order_amount oa
	ON o.order_id = oa.order_id
GROUP BY u.user_id
ORDER BY completed_total_spend DESC, u.user_id;

/*
题 2（JOIN + GROUP BY：按渠道统计）

**需求：**按 channel 统计 completed：

订单数

总收入

平均客单价（AOV）
*/
WITH order_amount AS(
	SELECT
		order_id,
        SUM(qty * unit_price) AS amount
	FROM order_items
    GROUP BY order_id
)
SELECT
	o.channel,
    COUNT(*) AS completed_order_cnt,
    SUM(oa.amount) AS total_revenue,
    AVG(oa.amount) AS avg_order_value
FROM orders o 
JOIN order_amount oa
	ON o.order_id = oa.order_id
WHERE o.status = 'completed'
GROUP BY o.channel
ORDER BY total_revenue DESC;

/*
题 3（多表 JOIN + COUNT DISTINCT + HAVING）

**需求：**找出在 completed 订单里，买过 ≥2 个不同 category 的用户，并输出：

distinct category 数

总消费
*/
SELECT
	o.user_id,
    COUNT(DISTINCT p.category) AS distinct_category_cnt,
    SUM(oi.qty * oi.unit_price) AS total_spend
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN products p
	ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY o.user_id
HAVING COUNT(DISTINCT p.category ) >= 2
ORDER BY total_spend DESC;

/*
题 4（窗口函数：每个用户最新 completed 订单）

**需求：**每个用户取 最新一笔 completed 订单（按 order_date，若同日用 order_id 再排序），
并输出订单金额。
*/
WITH order_amount AS(
	SELECT
		order_id,
        SUM(qty * unit_price) AS amount
	FROM order_items
    GROUP BY order_id
),
ranked AS(
	SELECT
		o.*,
        oa.amount,
        ROW_NUMBER() OVER(PARTITION BY o.user_id ORDER BY o.order_date DESC, o.order_id DESC) AS rn
	FROM orders o
    JOIN order_amount oa
		ON o.order_id = oa.order_id
	WHERE o.status = 'completed'
)
SELECT
	user_id, order_id, order_date, amount
FROM ranked
WHERE rn = 1
ORDER BY user_id;

/*
题 5（窗口函数：每个品类销售额 Top 2 产品）

**需求：**在所有订单明细里，
按 category 找 销售额最高的 Top 2 product（销售额=qty*unit_price 汇总）。
*/
WITH product_sales AS(
	SELECT
		p.category,
        oi.product_id,
        SUM(oi.qty* oi.unit_price) AS revenue
	FROM order_items oi
    JOIN products p
		ON oi.product_id = p.product_id
	GROUP BY p.category,oi.product_id
),
ranked AS(
	SELECT
		category,
        product_id,
        revenue,
        ROW_NUMBER() OVER(PARTITION BY category ORDER BY revenue DESC, product_id ASC) AS rn
	FROM product_sales
)
SELECT category,product_id, revenue
FROM ranked
WHERE rn <=2
ORDER BY category, rn;
