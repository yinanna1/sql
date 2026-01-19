USE interview_practice;
SELECT DATABASE();
SHOW TABLES;

CREATE DATABASE IF NOT EXISTS interview_practice;
USE interview_practice;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  customer_name VARCHAR(50)
);

CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  customer_id INT,
  order_date DATE,
  amount DECIMAL(10,2),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

USE interview_practice;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE orders;
TRUNCATE TABLE customers;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO customers VALUES
(1,'A'),(2,'B'),(3,'C');

SELECT DATABASE() AS db;
SELECT COUNT(*) AS orders_cnt FROM orders;
SELECT * FROM orders LIMIT 20;
TRUNCATE TABLE orders;

INSERT INTO orders VALUES
(101,1,'2026-01-10',20.00),
(102,1,'2026-01-12',35.00),
(103,1,'2026-01-15',15.00),
(201,2,'2026-01-11',50.00),
(202,2,'2026-01-18',10.00);


/*Q1
每个客户最近一笔订单（去重/最新）

核心：ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC)

USE interview_practice;
WITH ranked AS(
	SELECT
		o.*,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC, order_id DESC) AS rn
	FROM orders o
)
SELECT *
FROM ranked
WHERE rn = 1;
*/
/*Q2
题目描述：
给定员工表 employees(emp_id, emp_name, dept_id, salary)，请写 SQL 查询：

找出 每个部门（dept_id）工资最高的员工；

如果同一部门有多人 工资并列第一，需要 全部输出。

输出字段建议： dept_id, emp_id, emp_name, salary
*/
INSERT INTO employees (first_name, last_name, department, salary, hire_date, manager_id) VALUES
-- Engineering（并列最高：130000 两人）
('Alice', 'Wang',   'Engineering', 130000, '2022-03-01', NULL),
('Bob',   'Li',     'Engineering', 130000, '2021-07-15', 1),
('Cathy', 'Zhang',  'Engineering', 120000, '2023-01-10', 1),

-- Sales（最高：95000）
('David', 'Chen',   'Sales',       95000,  '2020-05-20', NULL),
('Eva',   'Liu',    'Sales',       88000,  '2022-11-02', 4),
('Frank', 'Zhao',   'Sales',       76000,  '2023-06-18', 4),

-- HR（并列最高：70000 两人）
('Grace', 'Sun',    'HR',          70000,  '2021-02-14', NULL),
('Henry', 'Zhou',   'HR',          70000,  '2022-09-30', 7),
('Ivy',   'Wu',     'HR',          65000,  '2024-04-05', 7),

-- Finance（最高：110000）
('Jack',  'Ma',     'Finance',     110000, '2019-08-09', NULL),
('Kira',  'He',     'Finance',     105000, '2021-12-12', 10);
/*
USE interview_practice;
WITH ranked AS(
	SELECT e.*,
		DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
	FROM employees e
)
SELECT *
FROM ranked
WHERE rn = 1
ORDER BY department, emp_id;
*/
/*Q3
题目描述：
给定员工表 employees(emp_id, first_name, last_name, department, salary, hire_date, manager_id)，请写 SQL：

对每个 department，找出 工资排名前 3 的员工；

如果第 3 名出现 并列，也要 全部返回（也就是“按工资档位 Top 3”，不是只返回 3 行）。

输出字段建议：
department, emp_id, first_name, last_name, salary
*/
/*
WITH ranked AS(
	SELECT
		e.*,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
	FROM employees e
)
SELECT *
FROM ranked
WHERE rn <= 3
ORDER BY department, emp_id;
*/

/*Q4
题目描述：
给定员工表 employees(emp_id, first_name, last_name, department, salary, hire_date, manager_id)，请写 SQL：

在每个 department 内，按 salary 从高到低排序

计算 截至当前员工为止 的 工资累计和（running total）

输出每个员工的：部门、姓名、工资、累计和

输出字段建议：
department, emp_id, first_name, last_name, salary, running_total
*/
/*USE interview_practice;
SELECT
    e.*,
    SUM(salary) OVER (PARTITION BY department ORDER BY salary DESC, emp_id
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM employees e
ORDER BY department, salary DESC, emp_id;
*/

/*
Q5
题目描述：
给定员工表 employees(emp_id, first_name, last_name, department, salary, hire_date, manager_id)，请写 SQL：

在每个 department 内，按 salary 从高到低排序

对每位员工，计算一个移动平均工资：取“当前员工 + 前面两位（更高薪的）员工”共 3 人 的平均工资

如果前面不够 2 人（比如部门第 1/2 名），就用现有的人数来算平均

输出字段建议：
department, emp_id, first_name, last_name, salary, ma_3

USE interview_practice;

SELECT
	*,
	AVG(salary) OVER (PARTITION BY department ORDER BY salary DESC, emp_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ma_3
FROM employees
ORDER BY department, salary DESC, emp_id;
*/

/*Q6
题目描述：

给定 employees(emp_id, first_name, last_name, department, salary, hire_date, manager_id)，请写 SQL：

在每个 department 内，按 hire_date 排序

找出那些员工，使得他与前 1 位、前 2 位员工都属于同部门（自然满足）并且在序列上连续（相邻记录）

输出这些员工（通常输出第三位及以后）

USE interview_practice;
WITH ranked AS(
	SELECT 
		e.*,
		ROW_NUMBER() OVER(PARTITION BY department ORDER BY hire_date, emp_id) AS rn
    FROM employees e
)
SELECT *
FROM ranked
WHERE rn >=3
ORDER BY department, rn;
*/

/*Q7
题目描述：
给定订单表 orders(order_id, customer_id, order_date, amount)，请写 SQL：

按月份统计每个月的 总销售额（SUM(amount)）

计算 环比差值：本月销售额 - 上月销售额
（可选：再算环比增长率）

输出字段建议：
month_start, month_sales, mom_diff（可选 mom_pct）
*/
/*
WITH monthly AS(
	SELECT 
        DATE_FORMAT(order_date, '%Y-%m-01') AS month_start,
        SUM(amount) AS month_sales
	FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
)
SELECT
	month_start, month_sales,
    month_sales - LAG(month_sales) OVER(ORDER BY month_start) as mom_diff,
    (month_sales - LAG(month_sales) OVER( ORDER BY month_start))
    / NULLIF(LAG(month_sales) OVER (ORDER BY month_start),0) AS mom_pct
FROM monthly
ORDER BY month_start;
*/
/*Q8
第 8 题：找出“没有下过订单的客户”（Customers with no orders）

题目描述：
给定两张表：

customers(customer_id, customer_name)

orders(order_id, customer_id, order_date, amount)

请写 SQL：找出 在 orders 中从未出现过 的客户（也就是没有任何订单的客户）。

输出字段建议：
customer_id, customer_name
*/
SELECT
	c.customer_id,
    c.customer_name
FROM customers c
LEFT JOIN orders o
	ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL;

/*Q9
第 9 题：找出“订单数 ≥ 2 的客户”（用 HAVING）

题目描述：
给定订单表 orders(order_id, customer_id, order_date, amount)，请写 SQL：

统计每个客户的订单数

找出 订单数 ≥ 2 的客户

输出字段建议：
customer_id, order_cnt
*/
SELECT
	customer_id,
    COUNT(*) AS order_cnt
FROM orders
GROUP BY customer_id
HAVING COUNT(*) >= 2;

/*Q10
第 10 题：NULL 统计与处理（COUNT(*) vs COUNT(col) + COALESCE）

题目描述：
给定订单表 orders(order_id, customer_id, order_date, amount)，请写 SQL 输出：

表里总共有多少行（COUNT(*)）

amount 非 NULL 的行数（COUNT(amount)）

amount 为 NULL 的行数

把 amount 的 NULL 当作 0，求总金额（SUM(COALESCE(amount,0))）

输出字段建议：
total_rows, non_null_amount_rows, null_amount_rows, sum_amount_null_as_zero
*/
SELECT
	COUNT(*) AS total_rows,
    COUNT(amount) AS non_null_amount_rows,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END)AS null_amount_rows,
    SUM(COALESCE(amount,0)) AS sum_amount_null_as_zero
FROM orders;