/*
Customers(id, name)

Orders(id, customer_id, order_date, status) // status 例：'paid' 'cancelled'

Payments(id, order_id, paid_amount, paid_at)

Logins(user_id, login_time)

Employees(id, name, salary, department_id)

Departments(id, name)
*/
/*#Q1
题目：返回所有没有任何订单的客户 id, name。
*/
SELECT
	c.id, c.name
FROM Customers c
LEFT JOIN Orders o
	ON o.customer_id = c.id
WHERE o.id IS NULL;

/*
题目：返回每个客户 customer_id、total_orders、paid_orders。客户没订单也要显示 0。
*/

SELECT
	c.id AS customer_id,
	COUNT(o.id) AS total_orders,
    SUM(CASE WHEN o.status = 'paid' THEN 1 ELSE 0 END) AS paid_orders
FROM Customers c
LEFT JOIN Orders o
	ON o.customer_id = c.id
GROUP BY c.id;

/*
题目：计算每个客户的 total_paid_amount（按 Payments 汇总），没支付也显示 0。
*/
SELECT
	c.id AS customer_id,
    COALESCE(SUM(p.paid_amount),0) AS total_paid_amount
FROM Customers c
LEFT JOIN Orders o
	ON o.customer_id = c.id
LEFT JOIN Payments p
	ON p.order_id = o.id
GROUP BY c.id;

/*
题目：返回每个用户最新一条登录记录 user_id, login_time。

答案（推荐：ROW_NUMBER）
*/
WITH x AS(
	SELECT user_id, login_time,
		ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY login_time DESC) AS rn
	FROM Logins
)
SELECT user_id, login_time
FROM x
WHERE rn = 1;

/*
题目：返回每个部门工资最高的员工（如果并列最高，全部返回），
输出 department_name, employee_name, salary。

*/
WITH ranked AS(
	SELECT
		d.name AS department_name,
        e.name AS employee_name,
        e.salary,
		RANK()OVER(PARTITION BY e.department_id ORDER BY e.salary DESC) AS rnk
	FROM Employees e
    JOIN Departments d
		ON d.id = e.department_id
)
SELECT
	department_name, employee_name, salary
FROM ranked
WHERE rnk = 1;

/*
题目：按客户、按支付时间排序，
输出每笔支付的累计金额：customer_id, paid_at, paid_amount, running_total
*/
WITH pay AS (
  SELECT o.customer_id,
         p.paid_at,
         p.paid_amount
  FROM Payments p
  JOIN Orders o
    ON o.id = p.order_id
)
SELECT customer_id,
       paid_at,
       paid_amount,
       SUM(paid_amount) OVER (
         PARTITION BY customer_id
         ORDER BY paid_at
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM pay
ORDER BY customer_id, paid_at;
