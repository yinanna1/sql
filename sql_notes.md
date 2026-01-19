今日主题：WHERE（行级过滤）+ NULL + LEFT JOIN 自连接

关键点 1:NULL 判断用 IS NULL / IS NOT NULL(不要 = NULL)

关键点 2：写 SQL 前先确认粒度：“一行代表什么？”

关键点 3：LEFT JOIN 保留左表全部行；匹配不到右表就显示 NULL

易错点：join 后行数变多 → 右表 key 可能不唯一 / join key 错

我今天跑通的验证：员工-经理 self join 查询 ✅

这是行级过滤，所以用 WHERE。

两个条件都要满足，所以用 AND。

只要 product_id，所以 SELECT product_id。

-Day2
WHERE：先过滤“行”

GROUP BY：把行分组后再聚合

HAVING：对“组”做过滤（聚合后筛选）

条件计数：SUM(CASE WHEN 条件 THEN 1 ELSE 0 END)

-Day3
1) Window function = 不压扁行的聚合 + 还能排序（保留明细行）
2) Top-N per group（每组 Top-N）

Use when： 每个用户/部门/类别取前 N 条（按某个指标排序）
WITH ranked AS (
  SELECT
    t.*,
    ROW_NUMBER() OVER (PARTITION BY grp_col ORDER BY metric_col DESC) AS rn
  FROM table_name t
)
SELECT *
FROM ranked
WHERE rn <= N;

3) Dedupe keep latest（去重保留最新一条）

Use when： 每个 user 只留最新记录 / 每个 key 保留最新状态
WITH ranked AS (
  SELECT
    t.*,
    ROW_NUMBER() OVER (PARTITION BY key_col ORDER BY ts_col DESC) AS rn
  FROM table_name t
)
SELECT *
FROM ranked
WHERE rn = 1;

4) Running total（累计）

Use when： 余额/累计消费/累计访问量
SELECT
  t.*,
  SUM(x) OVER (
    PARTITION BY grp_col
    ORDER BY dt_col
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_sum
FROM table_name t;

--Day 4
CTE vs Subquery（尤其 correlated subquery）：能说清楚什么时候用谁、优缺点、常见坑。
  CTE: 更容易读， 可分步， 便于复用。 常用在“先聚合再计算”“多步清洗”
  Subquery: 更适合一次性嵌套 
    correlated subquery常用于：“每组找最新”
  选择标准： 可读性、复用、是否需要多步
CASE + Conditional Aggregation：用一条 SQL 做多个口径（count/sum by 条件、占比）。

Date/Time + Trend：按天/周/月聚合、做 MoM/WoW、配合 LAG()。


ROW_NUMBER/RANK/DENSE_RANK 区别 : 
  ROW_NUMBER() gives unique 1..n; 
  RANK() gives same rank for ties and skips numbers;
  DENSE_RANK() give same rank for ties and doesn't skip
PARTITION BY:
  "restart the ranking/ calculation per group"
ORDER BY:
  inside OVER() = "define the sequence within each group"
LAG/LEAD:
  look at previous/next row in the same partition/order:
  LAG(col,1) OVER(PARTITION BY ... ORDER BY ...) for MoM/WoW deltas
running total 的写法:
  SUM(x) OVER(PARTITION BY grp ORDER BY dt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
Top-N per group :
  rank in a subquery/CTE, then filter: WHERE rn <= N 

--DAY 5
✅ JOIN 4 种：INNER / LEFT / 何时用 RIGHT（少用）/ self join

✅ 聚合：GROUP BY + HAVING 区别（面试必问）

✅ 去重：DISTINCT vs GROUP BY vs 窗口函数去重思路

✅ NULL：COUNT(*) vs COUNT(col)、COALESCE 常用场景